locals {
  use_watson_discovery        = (var.watson_discovery_instance_id != null) ? true : false
  use_watson_machine_learning = (var.watson_machine_learning_instance_guid != null) ? true : false
  use_elastic_index           = (var.elastic_instance_crn != null) ? true : false

  watsonx_assistant_url            = "//api.${var.watson_assistant_region}.assistant.watson.cloud.ibm.com/instances/${var.watson_assistant_instance_id}"
  watson_discovery_url             = local.use_watson_discovery ? "//api.${var.watson_discovery_region}.discovery.watson.cloud.ibm.com/instances/${var.watson_discovery_instance_id}" : null
  watson_discovery_project_name    = var.prefix != null ? "${var.prefix}-gen-ai-rag-sample-app-project" : "gen-ai-rag-sample-app-project"
  watson_discovery_collection_name = var.prefix != null ? "${var.prefix}-gen-ai-rag-sample-app-data" : "gen-ai-rag-sample-app-data"
  watson_ml_project_name           = var.prefix != null ? "${var.prefix}-RAG-sample-project" : "RAG-sample-project"
  sensitive_tokendata              = sensitive(data.ibm_iam_auth_token.tokendata.iam_access_token)

  elastic_index_name = var.prefix != null ? "${var.prefix}-${var.elastic_index_name}" : var.elastic_index_name

  cd_instance = var.create_continuous_delivery_service_instance ? ibm_resource_instance.cd_instance : null
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
  endpoint_type           = var.secrets_manager_endpoint_type
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
  endpoint_type           = var.secrets_manager_endpoint_type
}

# secrets manager secrets - WATSONX ADMIN API KEY
module "secrets_manager_secret_watsonx_admin_api_key" {
  providers = {
    ibm = ibm.sm_resources
  }
  count                   = (var.create_secrets && var.watsonx_admin_api_key != null) ? 1 : 0
  source                  = "terraform-ibm-modules/secrets-manager-secret/ibm"
  version                 = "1.3.1"
  region                  = var.secrets_manager_region
  secrets_manager_guid    = var.secrets_manager_guid
  secret_name             = "watsonx-admin-api-key"
  secret_description      = "WatsonX Admin API Key"
  secret_type             = "arbitrary" #checkov:skip=CKV_SECRET_6
  secret_payload_password = var.watsonx_admin_api_key
  endpoint_type           = var.secrets_manager_endpoint_type
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

module "configure_wml_project" {
  providers = {
    ibm.ibm_resources             = ibm.ibm_resources
    restapi.restapi_watsonx_admin = restapi.restapi_watsonx_admin
  }
  count                            = local.use_watson_machine_learning ? 1 : 0
  source                           = "../../modules/watson-machine-learning"
  watson_ml_instance_guid          = var.watson_machine_learning_instance_guid
  watson_ml_instance_crn           = var.watson_machine_learning_instance_crn
  watson_ml_instance_resource_name = var.watson_machine_learning_instance_resource_name
  watson_ml_project_name           = local.watson_ml_project_name
  resource_group_id                = module.resource_group.resource_group_id
  cos_instance_name                = "${var.prefix}-rag-sample-app-cos"
  location                         = var.watson_discovery_region # WatsonX services needs to be in the same region anyway
}

moved {
  from = module.configure_project
  to   = module.configure_wml_project[0].module.watson_ml_project
}

moved {
  from = module.configure_project.restapi_object.configure_project[0]
  to   = module.configure_wml_project[0].restapi_object.configure_project
}

moved {
  from = module.cos.module.cos_instance[0].ibm_resource_instance.cos_instance[0]
  to   = module.configure_wml_project[0].module.cos.module.cos_instance[0].ibm_resource_instance.cos_instance[0]
}

# Discovery project creation
module "configure_discovery_project" {
  count                                      = local.use_watson_discovery ? 1 : 0
  source                                     = "../../modules/watson-discovery"
  watson_discovery_url                       = local.watson_discovery_url
  watson_discovery_project_name              = local.watson_discovery_project_name
  watson_discovery_collection_name           = local.watson_discovery_collection_name
  watson_discovery_collection_artifacts_path = "${path.module}/artifacts/WatsonDiscovery"
  sensitive_tokendata                        = local.sensitive_tokendata
  depends_on                                 = [data.ibm_iam_auth_token.tokendata]
}

moved {
  from = restapi_object.configure_discovery_project
  to   = module.configure_discovery_project[0].restapi_object.configure_discovery_project
}
moved {
  from = restapi_object.configure_discovery_collection
  to   = module.configure_discovery_project[0].restapi_object.configure_discovery_collection
}

moved {
  from = null_resource.discovery_file_upload
  to   = module.configure_discovery_project[0].null_resource.discovery_file_upload
}

# Elastic index creation
module "configure_elastic_index" {
  providers = {
    ibm = ibm.ibm_resources
  }
  count                      = local.use_elastic_index ? 1 : 0
  source                     = "../../modules/elastic-index"
  elastic_credentials_name   = var.elastic_credentials_name
  elastic_index_name         = local.elastic_index_name
  elastic_instance_crn       = var.elastic_instance_crn
  elastic_index_entries_file = var.elastic_upload_sample_data ? "./artifacts/watsonx.Assistant/bank-loan-faqs.json" : null
  depends_on                 = [data.ibm_iam_auth_token.tokendata]
}

# Elastic index creation
module "configure_watson_assistant" {
  providers = {
    restapi.restapi_watsonx_admin = restapi.restapi_watsonx_admin
  }
  source                  = "../../modules/watson-assistant"
  watsonx_admin_api_key   = coalesce(var.watsonx_admin_api_key, var.ibmcloud_api_key)
  prefix                  = var.prefix
  watsonx_assistant_url   = local.watsonx_assistant_url
  assistant_search_skill  = local.use_elastic_index ? file("${path.module}/artifacts/watsonx.Assistant/elastic-search-skill.json") : null
  assistant_action_skill  = local.use_elastic_index ? file("${path.module}/artifacts/watsonx.Assistant/wxa-conv-srch-es-v1.json") : null
  elastic_service_binding = local.use_elastic_index ? module.configure_elastic_index[0].elastic_connection_binding : null
  depends_on              = [data.ibm_iam_auth_token.tokendata]
}
moved {
  from = shell_script.watson_assistant
  to   = module.configure_watson_assistant.shell_script.watson_assistant
}

### Make all pipeline properties dependent on CD instance
### to avoid errors when the toolchains are out of grace period

# Update CI pipeline with Assistant instance ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_id_pipeline_property_ci" {
  depends_on  = [local.cd_instance]
  provider    = ibm.ibm_resources
  name        = "watsonx_assistant_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CD pipeline with Assistant instance ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_id_pipeline_property_cd" {
  depends_on  = [local.cd_instance]
  provider    = ibm.ibm_resources
  name        = "watsonx_assistant_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CI pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_ci" {
  depends_on  = [local.cd_instance]
  provider    = ibm.ibm_resources
  name        = "app-flavor"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CD pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_cd" {
  depends_on  = [local.cd_instance]
  provider    = ibm.ibm_resources
  name        = "app-flavor"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CI pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_ci" {
  provider    = ibm.ibm_resources
  depends_on  = [local.cd_instance]
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = module.configure_watson_assistant.watsonx_assistant_integration_id
}

# Update CD pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_cd" {
  provider    = ibm.ibm_resources
  depends_on  = [local.cd_instance]
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = module.configure_watson_assistant.watsonx_assistant_integration_id
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
  depends_on     = [random_string.webhook_secret, local.cd_instance]
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
  provider    = ibm.ibm_resources
  depends_on  = [ibm_cd_tekton_pipeline_trigger.ci_pipeline_webhook, local.cd_instance]
  name        = "branch"
  pipeline_id = var.ci_pipeline_id
  trigger_id  = ibm_cd_tekton_pipeline_trigger.ci_pipeline_webhook.trigger_id
  type        = "text"
  value       = "main"
}

# Create git trigger for CD pipeline - to run inventory promotion once CI pipeline is complete
resource "ibm_cd_tekton_pipeline_trigger" "cd_pipeline_inventory_promotion_trigger" {
  provider       = ibm.ibm_resources
  depends_on     = [local.cd_instance]
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
