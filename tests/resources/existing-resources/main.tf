locals {
  signing_key_payload = sensitive("secret-signing-key-payload")
}

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
