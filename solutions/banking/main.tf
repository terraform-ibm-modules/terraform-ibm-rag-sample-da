locals {
  watsonx_assistant_url = "https://api.${var.watson_assistant_region}.assistant.watson.cloud.ibm.com/instances/${var.watson_assistant_instance_id}"
  watsonx_discovery_url = "https://api.${var.watson_discovery_region}.discovery.watson.cloud.ibm.com/instances/${var.watson_discovery_instance_id}"
  # unique_identifier     = random_string.unique_identifier.result
  sensitive_tokendata = sensitive(data.ibm_iam_auth_token.tokendata.iam_access_token)
}

# Access random string generated with random_string.unique_identifier.result
resource "random_string" "unique_identifier" {
  length  = 6
  special = false
  upper   = false
}

data "ibm_iam_auth_token" "tokendata" {}

# Resource group - create if it doesn't exist
# module "resource_group" {
#   source  = "terraform-ibm-modules/resource-group/ibm"
#   version = "1.1.5"
#   # If an existing resource group is not set (null), then create a new one
#   resource_group_name          = var.resource_group_name == null ? local.unique_identifier : null
#   existing_resource_group_name = var.resource_group_name
# }

# create COS instance for WatsonX.AI project
# module "cos" {
#   source            = "terraform-ibm-modules/cos/ibm//modules/fscloud"
#   version           = "7.5.3"
#   resource_group_id = module.resource_group.resource_group_id
#   cos_instance_name = "gen-ai-rag-sample-app-cos-instance"
#   cos_plan          = "standard"
# }

# create watsonX.AI user - do we need this?
# module "configure_user" {
#   source            = "./configure_user"
#   resource_group_id = module.resource_group.resource_group_id
# }


/*

# create watsonx.AI project
module "configure_project" {
  depends_on            = [module.configure_user]
  source                = "./configure_project"
  project_name          = var.project_name
  project_description   = var.project_description
  project_tags          = var.project_tags
  machine_learning_guid = ibm_resource_instance.machine_learning_instance.guid
  machine_learning_crn  = ibm_resource_instance.machine_learning_instance.crn
  machine_learning_name = ibm_resource_instance.machine_learning_instance.resource_name
  cos_guid              = module.cos.cos_instance_guid
  cos_crn               = module.cos.cos_instance_crn
  providers = {
    restapi = restapi.restapi_alias
  }
}

*/

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
