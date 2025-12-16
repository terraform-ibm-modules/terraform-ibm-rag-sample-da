locals {

  signing_key_payload = sensitive("secret-signing-key-payload")
  cluster_vpc_subnets = {
    default = [
      {
        id         = var.create_ocp_cluster ? ibm_is_subnet.subnet_zone_1[0].id : null
        cidr_block = var.create_ocp_cluster ? ibm_is_subnet.subnet_zone_1[0].ipv4_cidr_block : null
        zone       = var.create_ocp_cluster ? ibm_is_subnet.subnet_zone_1[0].zone : null
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2 # minimum of 2 is allowed when using single zone
      operating_system = "RHEL_9_64"
    }
  ]
}

########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# Elasticsearch
########################################################################################################################

module "elasticsearch" {
  source              = "terraform-ibm-modules/icd-elasticsearch/ibm"
  version             = "2.7.3"
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-es"
  region              = var.region
  service_endpoints   = "public-and-private"
  deletion_protection = false
  service_credential_names = {
    "elastic_db_admin" : "Administrator",
    "wxasst_db_user" : "Editor",
    "toolchain_db_user" : "Editor"
  }
}

##############################################################################
# Key Protect
##############################################################################

module "key_protect" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "5.5.3"
  key_protect_instance_name = "${var.prefix}-key-protect"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
}

########################################################################################################################
# Watson resources
########################################################################################################################


resource "ibm_resource_instance" "assistant_instance" {
  name              = "${var.prefix}-watson-assistant-instance"
  service           = "conversation"
  plan              = "plus"
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "ibm_resource_instance" "discovery_instance" {
  name              = "${var.prefix}-watson-discovery-instance"
  service           = "discovery"
  plan              = "plus"
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "ibm_resource_instance" "machine_learning_instance" {
  name              = "${var.prefix}-watson-machine-learning-instance"
  service           = "pm-20"
  plan              = "v2-standard"
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}



########################################################################################################################
# Pipeline resources
########################################################################################################################

resource "ibm_resource_instance" "cd_instance" {
  name              = "${var.prefix}-cd-instance"
  service           = "continuous-delivery"
  plan              = "professional"
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id
}

resource "ibm_cd_toolchain" "cd_toolchain_instance" {
  depends_on        = [ibm_resource_instance.cd_instance]
  name              = "${var.prefix}-toolchain-instance"
  resource_group_id = module.resource_group.resource_group_id
}

resource "ibm_cd_toolchain_tool_pipeline" "ci_toolchain_tool_pipeline_instance" {
  parameters {
    name = "${var.prefix}-pipeline-ci-01"
  }
  toolchain_id = ibm_cd_toolchain.cd_toolchain_instance.id
}

resource "ibm_cd_tekton_pipeline" "ci_tekton_pipeline_instance" {
  pipeline_id = ibm_cd_toolchain_tool_pipeline.ci_toolchain_tool_pipeline_instance.tool_id
}

resource "ibm_cd_toolchain_tool_pipeline" "cd_toolchain_tool_pipeline_instance" {
  parameters {
    name = "${var.prefix}-pipeline-cd-01"
  }
  toolchain_id = ibm_cd_toolchain.cd_toolchain_instance.id
}

resource "ibm_cd_tekton_pipeline" "cd_tekton_pipeline_instance" {
  pipeline_id = ibm_cd_toolchain_tool_pipeline.cd_toolchain_tool_pipeline_instance.tool_id
}



########################################################################################################################
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  count                     = var.create_ocp_cluster ? 1 : 0
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = []
}

resource "ibm_is_public_gateway" "gateway" {
  count          = var.create_ocp_cluster ? 1 : 0
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc[0].id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  count                    = var.create_ocp_cluster ? 1 : 0
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc[0].id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway[0].id
}


module "ocp_base" {

  count                               = var.create_ocp_cluster ? 1 : 0
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.70.0"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  tags                                = []
  cluster_name                        = var.prefix
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc[0].id
  vpc_subnets                         = local.cluster_vpc_subnets
  ocp_version                         = null
  worker_pools                        = local.worker_pools
  access_tags                         = []
  ocp_entitlement                     = null
  disable_outbound_traffic_protection = true # set as True to enable outbound traffic; required for accessing Operator Hub in the OpenShift console.
}
