########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

resource "ibm_resource_instance" "assistant_instance" {
  name              = "${var.prefix}-watson-assistant-instance"
  service           = "conversation"
  plan              = "plus"
  location          = var.watson_assistant_region
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
  location          = var.watson_discovery_region
  resource_group_id = module.resource_group.resource_group_id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

module "rag_sample_da" {
  source = "../.."
  ibmcloud_api_key = var.ibmcloud_api_key
  toolchain_region = var.toolchain_region
  ci_pipeline_id = var.ci_pipeline_id
  cd_pipeline_id = var.cd_pipeline_id
  watson_assistant_instance_id = ibm_resource_instance.assistant_instance.id
  watson_assistant_region = var.watson_assistant_region
  watson_discovery_instance_id = ibm_resource_instance.discovery_instance.id
  watson_discovery_region = var.watson_discovery_region
}
