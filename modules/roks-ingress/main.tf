locals {

  prefix_used = var.prefix != "" && var.prefix != null ? "${var.prefix}-" : ""
  # First entry in NLB DNS is the cluster's private ingress
  ingress_alb_hostname = data.ibm_container_nlb_dns.cluster_nlb_dns.nlb_config[0].lb_hostname

  containers_api_url = "https://containers.cloud.ibm.com/global"
  api_headers = {
    Authorization  = var.sensitive_tokendata
    "Content-Type" = "application/json"
  }

  ingress_subdomain   = shell_script.workload_nlb_dns.output.nlb_subdomain
  cluster_id          = shell_script.workload_nlb_dns.output.cluster_id
  ingress_secret_name = split(".", local.ingress_subdomain)[0]

  cluster_workload_ingress_alb_hostname = data.kubernetes_service_v1.ingress_router_service.status[0].load_balancer[0].ingress[0].hostname

  nlb_dns_data = jsonencode({
    cluster      = var.cluster_name
    dnsType      = "public"
    nlbSubdomain = local.ingress_subdomain
    lbHostname   = local.cluster_workload_ingress_alb_hostname # new ALB provisioned by the ingress controller
    #checkov:skip=CKV_SECRET_6:This is a designated namespace for igress TLS certificate
    secretNamespace = "openshift-ingress"
    type            = "public"
  })

  # Pick the first "Deny all" rule in the ACL to place new rules before that
  cluster_acl_deny_rule = length([for rule in data.ibm_is_network_acl_rules.alb_acl_rules.rules : rule.rule_id if rule.action == "deny"]) > 0 ? [for rule in data.ibm_is_network_acl_rules.alb_acl_rules.rules : rule.rule_id if rule.action == "deny"][0] : null


}

data "ibm_container_nlb_dns" "cluster_nlb_dns" {
  cluster = var.cluster_name
}

# First create an NLB DNS entry - it will pick the next NLB DNS index for the name like
# <cluster name>-<guid>-<NLB DNS index>.<region>.containers.appdomain.cloud
# Initially the NLB DNS will point to the cluster's default load balancer
# Once the ingress controller provisions new public ALB, this NLB DNS entry will be updated
#
# The http provider only has a data source, so it cannot create and delete the entry.
# The lifecycle is handled by curl calls in scripts/nlb-dns-utils.sh. On destroy the script
# removes the domain (ingress/v2/dns/deleteDomain) and then the TLS secret (v2/nlb-dns/deleteSecret).
resource "shell_script" "workload_nlb_dns" {
  lifecycle_commands {
    create = <<-EOT
      set -e
      source ./${path.module}/scripts/nlb-dns-utils.sh
      create_nlb_dns
    EOT
    read   = <<-EOT
      set -e
      source ./${path.module}/scripts/nlb-dns-utils.sh
      read_nlb_dns
    EOT
    delete = <<-EOT
      set -e
      source ./${path.module}/scripts/nlb-dns-utils.sh
      delete_nlb_dns
    EOT
  }

  environment = {
    CONTAINERS_API_URL = local.containers_api_url
    CLUSTER_NAME       = var.cluster_name
    LB_HOSTNAME        = local.ingress_alb_hostname
  }

  sensitive_environment = {
    IBMCLOUD_API_KEY = var.ibmcloud_api_key
  }

  lifecycle {
    # Change in apikey should not trigger re-create. The initial load balancer hostname is only
    # used at creation time; the entry is re-pointed to the ingress ALB by the data source below.
    ignore_changes = [sensitive_environment, environment["LB_HOSTNAME"]]
  }
}

# ALB private IPs take some time to get available - needed for ACL update
resource "time_sleep" "wait_for_alb_provisioning" {
  depends_on = [shell_script.workload_nlb_dns]

  destroy_duration = "5s"
  create_duration  = "10m"
}

# Public ingress controller will result in provisioning a public load balancer in the cluster's VPC
# assigned to worker nodes subnets
resource "kubernetes_manifest" "workload_ingress" {
  manifest = {
    apiVersion = "operator.openshift.io/v1"
    kind       = "IngressController"
    metadata = {
      name      = "${local.prefix_used}${var.public_ingress_controller_name}"
      namespace = "openshift-ingress-operator"
    }
    spec = {
      replicas = 2
      domain   = local.ingress_subdomain
      defaultCertificate = {
        name = local.ingress_secret_name
      }
      routeSelector = {
        matchLabels = {
          ingress = var.public_ingress_selector_label
        }
      }
      endpointPublishingStrategy = {
        type = "LoadBalancerService"
        loadBalancer = {
          dnsManagementPolicy = "Managed"
          scope               = "External"
        }
      }
    }
  }
  wait {
    # Wait until the load balancer is provisioned
    # The subsequent wait will give time for the ALB to finish provisioning (private IPs are available)
    # The ingress controller will become fully available when the TLS secret is created, but that may take much longer
    condition {
      type   = "LoadBalancerReady"
      status = "True"
    }
  }
  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Give some more time for ALB private IPs to become available in case only the ingress is being re-created
resource "time_sleep" "wait_for_ingress_provisioning" {
  depends_on = [shell_script.workload_nlb_dns, kubernetes_manifest.workload_ingress]

  destroy_duration = "5s"
  create_duration  = "7m"
  triggers = {
    ingress_uid = kubernetes_manifest.workload_ingress.object.metadata.uid
  }
}

data "kubernetes_service_v1" "ingress_router_service" {
  depends_on = [time_sleep.wait_for_ingress_provisioning]
  metadata {
    name      = "router-${kubernetes_manifest.workload_ingress.object.metadata.name}"
    namespace = "openshift-ingress"
  }
}

# Point the NLB DNS entry to the new ALB created by the ingress controller.
# The http provider only has a data source, so this POST runs on every plan and apply.
# The call is idempotent: it sets the same load balancer hostname each time.
data "http" "workload_nlb_dns_patch" {
  url             = "${local.containers_api_url}/v2/nlb-dns/vpc/replaceLBHostname"
  method          = "POST"
  request_headers = local.api_headers
  request_body    = local.nlb_dns_data

  retry {
    attempts     = 3
    min_delay_ms = 5000
  }

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 202, 204], self.status_code)
      error_message = "Updating the NLB DNS load balancer hostname failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}

# Drop the old restapi objects from state without calling their destroy:
# the stub destroy of workload_nlb_dns did nothing, and the deleteSecret / deleteDomain
# calls of the patch and cleanup objects are now done by the shell_script delete above.
removed {
  from = restapi_object.workload_nlb_dns
  lifecycle {
    destroy = false
  }
}

removed {
  from = restapi_object.workload_nlb_dns_patch
  lifecycle {
    destroy = false
  }
}

removed {
  from = restapi_object.workload_nlb_dns_cleanup
  lifecycle {
    destroy = false
  }
}

# Need to get private IPs (private_ips) of the ALB to include in ACL
data "ibm_is_lb" "ingress_vpc_alb" {
  name       = "kube-${local.cluster_id}-${replace(data.kubernetes_service_v1.ingress_router_service.metadata[0].uid, "-", "")}"
  depends_on = [time_sleep.wait_for_alb_provisioning, time_sleep.wait_for_ingress_provisioning, data.http.workload_nlb_dns_patch]
}

# Assuming all SLZ zones for the ALB subnet will have the same ACL
data "ibm_is_subnet" "cluster_subnet" {
  identifier = tolist(data.ibm_is_lb.ingress_vpc_alb.subnets)[0]
}

data "ibm_is_network_acl" "alb_acl" {
  network_acl = data.ibm_is_subnet.cluster_subnet.network_acl
}
data "ibm_is_network_acl_rules" "alb_acl_rules" {
  network_acl = data.ibm_is_network_acl.alb_acl.id
}

# Add ACL rules to allow HTTPS requests from the outside to the new public load balancer
resource "ibm_is_network_acl_rule" "alb_https_req" {
  count           = var.cluster_zone_count
  network_acl     = data.ibm_is_network_acl.alb_acl.id
  before          = local.cluster_acl_deny_rule
  name            = "${local.prefix_used}public-ingress-lba-zone${count.index + 1}-https-req"
  action          = "allow"
  source          = "0.0.0.0/0"
  destination     = "${data.ibm_is_lb.ingress_vpc_alb.private_ips[count.index]}/32"
  direction       = "inbound"
  protocol        = "tcp"
  port_min        = 443
  port_max        = 443
  source_port_min = 1024
  source_port_max = 65535
  lifecycle {
    ignore_changes = [before]
  }
}

resource "ibm_is_network_acl_rule" "alb_https_resp" {
  count           = var.cluster_zone_count
  network_acl     = data.ibm_is_network_acl.alb_acl.id
  before          = local.cluster_acl_deny_rule
  name            = "${local.prefix_used}public-ingress-lba-zone${count.index + 1}-https-resp"
  action          = "allow"
  source          = "${data.ibm_is_lb.ingress_vpc_alb.private_ips[count.index]}/32"
  destination     = "0.0.0.0/0"
  direction       = "outbound"
  protocol        = "tcp"
  port_min        = 1024
  port_max        = 65535
  source_port_min = 443
  source_port_max = 443
  lifecycle {
    ignore_changes = [before]
  }
}
