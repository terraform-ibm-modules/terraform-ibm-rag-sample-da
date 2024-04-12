locals {
  watsonx_assistant_url = "https://api.${var.watson_assistant_region}.assistant.watson.cloud.ibm.com/instances/${var.watson_assistant_instance_id}"
  watsonx_discovery_url = "https://api.${var.watson_discovery_region}.discovery.watson.cloud.ibm.com/instances/${var.watson_discovery_instance_id}"
  sensitive_tokendata   = sensitive(data.ibm_iam_auth_token.tokendata.iam_access_token)
}

data "ibm_iam_auth_token" "tokendata" {}

# Resource group - create if it doesn't exist
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.5"
  resource_group_name          = var.use_existing_resource_group == false ? var.resource_group_name : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

# create COS instance for WatsonX.AI project
module "cos" {
  source            = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version           = "7.5.3"
  resource_group_id = module.resource_group.resource_group_id
  cos_instance_name = "${var.prefix}-rag-sample-app-cos"
  cos_plan          = "standard"
}

data "ibm_resource_group" "toolchain_resource_group_id" {
  name = var.toolchain_resource_group
}

# create CD service for toolchain use if variable is set
resource "ibm_resource_instance" "cd_instance" {
  count             = var.create_continuous_delivery_service_instance ? 1 : 0
  name              = "${var.prefix}-cd-instance"
  service           = "continuous-delivery"
  plan              = "professional"
  location          = var.toolchain_region
  resource_group_id = data.ibm_resource_group.toolchain_resource_group_id.id
}

# create watsonX.AI user - do we need this?
# module "configure_user" {
#   source            = "./configure_user"
#   resource_group_id = module.resource_group.resource_group_id
# }

# create watsonx.AI project
module "configure_project" {
  source                = "github.com/terraform-ibm-modules/terraform-ibm-watsonx-saas-da.git//configure_project?ref=v0.2.0"
  project_name          = "RAG-sample-project"
  project_description   = "WatsonX AI project for RAG pattern sample app"
  project_tags          = ["watsonx-ai-SaaS", "RAG-sample-project"]
  machine_learning_guid = var.watson_machine_learning_instance_guid
  machine_learning_crn  = var.watson_machine_learning_instance_crn
  machine_learning_name = var.watson_machine_learning_instance_resource_name
  cos_guid              = module.cos.cos_instance_guid
  cos_crn               = module.cos.cos_instance_crn
}

# get zip file from code repo
# add deployment space - not for demo scope

# discovery project creation
# possibly change type of project here - TBC
resource "null_resource" "discovery_project_creation" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/watson-scripts/discovery-project-creation.sh \"${local.sensitive_tokendata}\" \"${local.watsonx_discovery_url}\""
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
  }
}

# discovery collection creation
resource "null_resource" "discovery_collection_creation" {
  depends_on = [null_resource.discovery_project_creation]
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/watson-scripts/discovery-collection-creation.sh \"${local.sensitive_tokendata}\" \"${local.watsonx_discovery_url}\""
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
  }
}

# discovery file upload
resource "null_resource" "discovery_file_upload" {
  depends_on = [null_resource.discovery_collection_creation]
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/watson-scripts/discovery-file-upload.sh \"${local.sensitive_tokendata}\" \"${local.watsonx_discovery_url}\" \"${path.module}/artifacts/WatsonDiscovery\" "
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
  }
}

# assistant creation
resource "null_resource" "assistant_project_creation" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/watson-scripts/assistant-project-creation.sh \"${local.sensitive_tokendata}\" \"${local.watsonx_assistant_url}\""
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
  }
}

# assistant custom extensions
# manual step - awaiting API

# assistant skills import
# skip for now - depends on manual step for custom extensions
/*
resource "null_resource" "assistant_import_rag_pattern-action-skill" {
  triggers = {
    always_run = timestamp()
    ibmcloud_api_key     = var.ibmcloud_api_key
    watsonx_assistant_url = local.watsonx_assistant_url
  }

  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      ASSISTANT_ID=$(curl -X GET -u "apikey:${var.ibmcloud_api_key}" "${local.watsonx_assistant_url}/v2/assistants?version=2023-06-15" \
        | jq '.assistants[] | select(.name == "gen-ai-rag-sample-app-assistant") | .assistant_id ')

      curl -X POST -u "apikey:${var.ibmcloud_api_key}" --header "Content-Type: application/json" \
         --data "@./artifacts/watsonX.Assistant/cc-bank-loan-v1-action.json" \
         "${local.watsonx_assistant_url}/v2/assistants/$ASSISTANT_ID/skills_import?version=2023-06-15"
    EOF
  }
}
*/

# get assistant integration ID
data "external" "assistant_get_integration_id" {
  depends_on = [null_resource.assistant_project_creation]
  program    = ["bash", "${path.module}/watson-scripts/assistant-get-integration-id.sh"]
  query = {
    tokendata            = local.sensitive_tokendata
    watson_assistant_url = local.watsonx_assistant_url
  }
}

# Update CI pipeline with Assistant instance ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_id_pipeline_property_ci" {
  name        = "watsonx_assistant_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CD pipeline with Assistant instance ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_id_pipeline_property_cd" {
  name        = "watsonx_assistant_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CI pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_ci" {
  name        = "app-flavor"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CD pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_cd" {
  name        = "app-flavor"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CI pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_ci" {
  depends_on  = [data.external.assistant_get_integration_id]
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = data.external.assistant_get_integration_id.result.assistant_integration_id
}

# Update CD pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_cd" {
  depends_on  = [data.external.assistant_get_integration_id]
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = data.external.assistant_get_integration_id.result.assistant_integration_id
}
