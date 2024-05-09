locals {
  watsonx_assistant_url = "https://api.${var.watson_assistant_region}.assistant.watson.cloud.ibm.com/instances/${var.watson_assistant_instance_id}"
  watsonx_discovery_url = "//api.${var.watson_discovery_region}.discovery.watson.cloud.ibm.com/instances/${var.watson_discovery_instance_id}"
  sensitive_tokendata   = sensitive(data.ibm_iam_auth_token.tokendata.iam_access_token)
}

data "ibm_iam_auth_token" "tokendata" {}

# Resource group - create if it doesn't exist
module "resource_group" {
  providers = {
    ibm = ibm.ibm_resources
  }
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.5"
  resource_group_name          = var.use_existing_resource_group == false ? var.resource_group_name : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

# create COS instance for WatsonX.AI project
module "cos" {
  providers = {
    ibm = ibm.ibm_resources
  }
  source            = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version           = "8.2.1"
  resource_group_id = module.resource_group.resource_group_id
  cos_instance_name = "${var.prefix}-rag-sample-app-cos"
  cos_plan          = "standard"
}

# secrets manager secrets - IBM IAM API KEY
module "secrets_manager_secret_ibm_iam" {
  providers = {
    ibm = ibm.sm_resources
  }
  count                   = var.create_secrets ? 1 : 0
  source                  = "terraform-ibm-modules/secrets-manager-secret/ibm"
  version                 = "1.3.1"
  region                  = var.secrets_manager_region
  secrets_manager_guid    = var.secrets_manager_guid
  secret_name             = "ibmcloud-api-key"
  secret_description      = "IBM IAM Api key"
  secret_type             = "arbitrary" #checkov:skip=CKV_SECRET_6
  secret_payload_password = var.ibmcloud_api_key
}

# secrets manager secrets - IBM signing key
module "secrets_manager_secret_signing_key" {
  providers = {
    ibm = ibm.sm_resources
  }
  count                   = var.create_secrets ? 1 : 0
  source                  = "terraform-ibm-modules/secrets-manager-secret/ibm"
  version                 = "1.3.1"
  region                  = var.secrets_manager_region
  secrets_manager_guid    = var.secrets_manager_guid
  secret_name             = "signing-key"
  secret_description      = "IBM Signing GPG key"
  secret_type             = "arbitrary" #checkov:skip=CKV_SECRET_6
  secret_payload_password = var.signing_key
}

data "ibm_resource_group" "toolchain_resource_group_id" {
  provider = ibm.ibm_resources
  name     = var.toolchain_resource_group
}

# create CD service for toolchain use if variable is set
resource "ibm_resource_instance" "cd_instance" {
  provider          = ibm.ibm_resources
  count             = var.create_continuous_delivery_service_instance ? 1 : 0
  name              = "${var.prefix}-cd-instance"
  service           = "continuous-delivery"
  plan              = "professional"
  location          = var.toolchain_region
  resource_group_id = data.ibm_resource_group.toolchain_resource_group_id.id
}

# create watsonx.AI project
module "configure_project" {
  watsonx_admin_api_key = var.watsonx_admin_api_key != null ? var.watsonx_admin_api_key : var.ibmcloud_api_key
  source                = "github.com/terraform-ibm-modules/terraform-ibm-watsonx-saas-da.git//configure_project?ref=v0.5.5"
  project_name          = "${var.prefix}-RAG-sample-project"
  project_description   = "WatsonX AI project for RAG pattern sample app"
  project_tags          = ["watsonx-ai-SaaS", "RAG-sample-project"]
  machine_learning_guid = var.watson_machine_learning_instance_guid
  machine_learning_crn  = var.watson_machine_learning_instance_crn
  machine_learning_name = var.watson_machine_learning_instance_resource_name
  cos_guid              = module.cos.cos_instance_guid
  cos_crn               = module.cos.cos_instance_crn
}

# Discovery project creation
resource "restapi_object" "configure_discovery_project" {
  depends_on     = [data.ibm_iam_auth_token.tokendata]
  path           = local.watsonx_discovery_url
  read_path      = "${local.watsonx_discovery_url}/v2/projects/{id}?version=2023-03-31"
  read_method    = "GET"
  create_path    = "${local.watsonx_discovery_url}/v2/projects?version=2023-03-31"
  create_method  = "POST"
  id_attribute   = "project_id"
  destroy_method = "DELETE"
  destroy_path   = "${local.watsonx_discovery_url}/v2/projects/{id}?version=2023-03-31"
  data           = <<-EOT
                  {
                    "name": "gen-ai-rag-sample-app-project",
                    "type": "document_retrieval"
                  }
                  EOT
  update_method  = "POST"
  update_path    = "${local.watsonx_discovery_url}/v2/projects/{id}?version=2023-03-31"
  update_data    = <<-EOT
                  {
                    "name": "gen-ai-rag-sample-app-project",
                    "type": "document_retrieval"
                  }
                  EOT
}

# Discovery collection creation
resource "restapi_object" "configure_discovery_collection" {
  depends_on     = [data.ibm_iam_auth_token.tokendata, restapi_object.configure_discovery_project]
  path           = local.watsonx_discovery_url
  read_path      = "${local.watsonx_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections/{id}?version=2023-03-31"
  read_method    = "GET"
  create_path    = "${local.watsonx_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections?version=2023-03-31"
  create_method  = "POST"
  id_attribute   = "collection_id"
  destroy_method = "DELETE"
  destroy_path   = "${local.watsonx_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections/{id}?version=2023-03-31"
  data           = <<-EOT
                  {
                    "name": "gen-ai-rag-sample-app-data",
                    "description": "Sample data"
                  }
                  EOT
  update_method  = "POST"
  update_path    = "${local.watsonx_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections/{id}?version=2023-03-31"
  update_data    = <<-EOT
                  {
                    "name": "gen-ai-rag-sample-app-data",
                    "description": "Sample data"
                  }
                  EOT
}

# discovery file upload
resource "null_resource" "discovery_file_upload" {
  depends_on = [restapi_object.configure_discovery_collection]
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/watson-scripts/discovery-file-upload.sh \"https:${local.watsonx_discovery_url}\" \"${restapi_object.configure_discovery_project.id}\" \"${restapi_object.configure_discovery_collection.id}\" \"${path.module}/artifacts/WatsonDiscovery\" "
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
    environment = {
      IAM_TOKEN = local.sensitive_tokendata
    }
  }
}

# assistant creation
resource "null_resource" "assistant_project_creation" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/watson-scripts/assistant-project-creation.sh \"${local.watsonx_assistant_url}\""
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
    environment = {
      IAM_TOKEN = local.sensitive_tokendata
    }
  }
}

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
  provider    = ibm.ibm_resources
  name        = "watsonx_assistant_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CD pipeline with Assistant instance ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_id_pipeline_property_cd" {
  provider    = ibm.ibm_resources
  name        = "watsonx_assistant_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CI pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_ci" {
  provider    = ibm.ibm_resources
  name        = "app-flavor"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CD pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_cd" {
  provider    = ibm.ibm_resources
  name        = "app-flavor"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CI pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_ci" {
  provider    = ibm.ibm_resources
  depends_on  = [data.external.assistant_get_integration_id]
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = data.external.assistant_get_integration_id.result.assistant_integration_id
}

# Update CD pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_cd" {
  provider    = ibm.ibm_resources
  depends_on  = [data.external.assistant_get_integration_id]
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = data.external.assistant_get_integration_id.result.assistant_integration_id
}

# Random string for webhook token
resource "random_string" "webhook_secret" {
  length  = 48
  special = false
  upper   = false
}

# Create webhook for CI pipeline
resource "ibm_cd_tekton_pipeline_trigger" "ci_pipeline_webhook" {
  provider       = ibm.ibm_resources
  depends_on     = [random_string.webhook_secret]
  type           = "generic"
  pipeline_id    = var.ci_pipeline_id
  name           = "rag-webhook-trigger"
  event_listener = "ci-listener-gitlab"
  secret {
    type     = "token_matches"
    source   = "payload"
    key_name = "webhook-token"
    value    = random_string.webhook_secret.result
  }
}

# Ensure webhook trigger runs against correct git branch
resource "ibm_cd_tekton_pipeline_trigger_property" "ci_pipeline_webhook_branch_property" {
  depends_on  = [ibm_cd_tekton_pipeline_trigger.ci_pipeline_webhook]
  name        = "branch"
  pipeline_id = var.ci_pipeline_id
  trigger_id  = ibm_cd_tekton_pipeline_trigger.ci_pipeline_webhook.trigger_id
  type        = "text"
  value       = "main"
}

# Create git trigger for CD pipeline - to run inventory promotion once CI pipeline is complete
resource "ibm_cd_tekton_pipeline_trigger" "cd_pipeline_inventory_promotion_trigger" {
  provider       = ibm.ibm_resources
  count          = var.inventory_repo_url != null ? 1 : 0
  type           = "scm"
  pipeline_id    = var.cd_pipeline_id
  name           = "git-inventory-promotion-trigger"
  event_listener = "promotion-listener"
  events         = ["push"]
  source {
    type = "git"
    properties {
      url    = var.inventory_repo_url
      branch = "master"
    }
  }
}

# Trigger webhook to start CI pipeline run
resource "null_resource" "ci_pipeline_run" {
  count = var.trigger_ci_pipeline_run == true ? 1 : 0
  depends_on = [
    ibm_cd_tekton_pipeline_trigger.ci_pipeline_webhook,
    ibm_cd_tekton_pipeline_trigger_property.ci_pipeline_webhook_branch_property,
    ibm_cd_tekton_pipeline_property.watsonx_assistant_integration_id_pipeline_property_ci,
    ibm_cd_tekton_pipeline_property.watsonx_assistant_id_pipeline_property_ci,
    ibm_resource_instance.cd_instance
  ]
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/watson-scripts/webhook-trigger.sh \"${ibm_cd_tekton_pipeline_trigger.ci_pipeline_webhook.webhook_url}\" \"${random_string.webhook_secret.result}\""
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
  }
}
