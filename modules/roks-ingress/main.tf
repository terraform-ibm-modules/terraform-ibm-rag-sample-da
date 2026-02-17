locals {

  prefix_used = var.prefix != "" && var.prefix != null ? "${var.prefix}-" : ""
  # First entry in NLB DNS is the cluster's private ingress
  ingress_alb_hostname = data.ibm_container_nlb_dns.cluster_nlb_dns.nlb_config[0].lb_hostname

  workload_nlb_dns_data = jsondecode(restapi_object.workload_nlb_dns.create_response)

  # NLB DNS API returns different structures in create and read operations
  ingress_subdomain   = can(local.workload_nlb_dns_data.Nlb) ? local.workload_nlb_dns_data.Nlb.nlbSubdomain : local.workload_nlb_dns_data.nlbSubdomain
  cluster_id          = can(local.workload_nlb_dns_data.Nlb) ? local.workload_nlb_dns_data.Nlb.cluster : local.workload_nlb_dns_data.cluster
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
resource "restapi_object" "workload_nlb_dns" {
  path          = "/v2/nlb-dns/getNlbDetails"
  read_path     = "/v2/nlb-dns/getNlbDetails?cluster=${var.cluster_name}&nlbSubdomain={id}"
  read_method   = "GET"
  create_path   = "/v2/nlb-dns/vpc/createNlbDNS"
  create_method = "POST"
  data = jsonencode({
    cluster         = var.cluster_name
    dnsType         = "public"
    lbHostname      = local.ingress_alb_hostname
    secretNamespace = "openshift-ingress"
    type            = "public"
  })
  id_attribute = "nlbSubdomain"
  # The destruction cannot be handled in this resources because the {id} needs to be in the request body
  # and the create and read API data structures do not match so copy_keys are not working as intended
  # This is just a stub to avoid API errors, the actual remove operation will be done in the "patch/cleanup" resource
  destroy_method = "GET"
  destroy_path   = "/v2/nlb-dns/getNlbDetails?cluster=${var.cluster_name}&nlbSubdomain={id}"
  # Update is also a stub - it needs the {id} (nlbSubdomain in the request body)
  update_method = "GET"
  update_path   = "/v2/nlb-dns/getNlbDetails?cluster=${var.cluster_name}&nlbSubdomain={id}"
}

# ALB private IPs take some time to get available - needed for ACL update
resource "time_sleep" "wait_for_alb_provisioning" {
  depends_on = [restapi_object.workload_nlb_dns]

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
  depends_on = [restapi_object.workload_nlb_dns, kubernetes_manifest.workload_ingress]

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

# The "patch" resource is needed to update the ALB hostname in the NLB DNS entry
# to point to the new ALB created by the ingress controller
# It will update the resource created by restapi_object" "workload_nlb_dns
# and on destroy will delete the TLS secret
resource "restapi_object" "workload_nlb_dns_patch" {
  path         = "/v2/nlb-dns/getNlbDetails"
  query_string = "cluster=${var.cluster_name}&nlbSubdomain=${local.ingress_subdomain}"
  read_path    = "/v2/nlb-dns/getNlbDetails"
  read_method  = "GET"
  # Update existing entry with new ALB hostname instead of creating a new one
  create_path    = "/v2/nlb-dns/vpc/replaceLBHostname"
  create_method  = "POST"
  data           = local.nlb_dns_data
  object_id      = local.ingress_subdomain
  destroy_method = "POST"
  destroy_path   = "/v2/nlb-dns/deleteSecret"
  # Delete ingress secret, the NLB DNS is removed by the resource creating it
  destroy_data = jsonencode({
    cluster   = var.cluster_name
    subdomain = local.ingress_subdomain
  })
  update_method = "POST"
  update_path   = "/v2/nlb-dns/vpc/replaceLBHostname"
  update_data   = local.nlb_dns_data
}

# This resource is just to implement the destroy operation because it cannot be done
# in the resource that creates the NLB DNS entry (see comment on restapi_object.workload_nlb_dns)
resource "restapi_object" "workload_nlb_dns_cleanup" {
  path         = "/v2/nlb-dns/getNlbDetails"
  query_string = "cluster=${var.cluster_name}&nlbSubdomain=${local.ingress_subdomain}"
  read_path    = "/v2/nlb-dns/getNlbDetails"
  read_method  = "GET"
  # Update existing entry with new ALB hostname instead of creating a new one
  create_path   = "/v2/nlb-dns/vpc/replaceLBHostname"
  create_method = "POST"
  data          = local.nlb_dns_data
  object_id     = local.ingress_subdomain
  # Delete the ALB assignment from the NLB DNS, needs to use ingress/v2/dns API, otherwise the NLB DNS entry is not deleted
  destroy_method = "POST"
  destroy_path   = "/ingress/v2/dns/deleteDomain"
  destroy_data = jsonencode({
    cluster   = var.cluster_name
    subdomain = local.ingress_subdomain
  })
  update_method = "POST"
  update_path   = "/v2/nlb-dns/vpc/replaceLBHostname"
  update_data   = local.nlb_dns_data
  depends_on    = [restapi_object.workload_nlb_dns_patch]
}

# Need to get private IPs (private_ips) of the ALB to include in ACL
data "ibm_is_lb" "ingress_vpc_alb" {
  name       = "kube-${local.cluster_id}-${replace(data.kubernetes_service_v1.ingress_router_service.metadata[0].uid, "-", "")}"
  depends_on = [time_sleep.wait_for_alb_provisioning, time_sleep.wait_for_ingress_provisioning]
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
  port_max        = 443
  port_min        = 443
  source_port_max = 65535
  source_port_min = 1024

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
  port_max        = 65535
  port_min        = 1024
  source_port_max = 443
  source_port_min = 443
  lifecycle {
    ignore_changes = [before]
  }
}
