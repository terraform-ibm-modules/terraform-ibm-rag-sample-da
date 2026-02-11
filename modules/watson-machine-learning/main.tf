# create COS instance for WatsonX.AI project
module "cos" {
  providers = {
    ibm = ibm.ibm_resources
  }
  source            = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version           = "10.9.9"
  resource_group_id = var.resource_group_id
  cos_instance_name = var.cos_instance_name
  cos_plan          = "standard"
}

module "storage_delegation" {
  providers = {
    ibm                           = ibm
    restapi.restapi_watsonx_admin = restapi.restapi_watsonx_admin
  }
  source            = "git::https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-ai.git//modules/storage_delegation?ref=v2.15.1"
  count             = var.watsonx_project_delegated ? 1 : 0
  cos_kms_key_crn   = var.cos_kms_key_crn
  cos_instance_guid = module.cos.cos_instance_guid
}

# parse the crn for region and guid
module "crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.4.1"
  crn     = var.watson_ml_instance_crn
}

locals {
  watson_ml_instance_guid   = module.crn_parser.service_instance
  watson_ml_instance_region = module.crn_parser.region
}

module "watson_ml_project" {
  providers = {
    ibm     = ibm.ibm_resources
    restapi = restapi.restapi_watsonx_admin
  }

  source     = "git::https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-ai.git//modules/configure_project?ref=v2.15.1"
  depends_on = [module.storage_delegation]

  project_name              = var.watson_ml_project_name
  project_description       = var.watson_ml_project_description
  project_tags              = var.watson_ml_project_tags
  watsonx_project_delegated = var.watsonx_project_delegated
  mark_as_sensitive         = var.watson_ml_project_sensitive
  region                    = local.watson_ml_instance_region
  cos_guid                  = module.cos.cos_instance_guid
  cos_crn                   = module.cos.cos_instance_crn
  watsonx_ai_runtime_name   = var.watson_ml_instance_resource_name
  watsonx_ai_runtime_guid   = local.watson_ml_instance_guid
  watsonx_ai_runtime_crn    = var.watson_ml_instance_crn
}

moved {
  from = restapi_object.configure_project
  to   = module.watson_ml_project.restapi_object.configure_project
}

/* Reading the project after creating it has some issues with the API - we do not need that data yet
resource "time_sleep" "wait_60_seconds" { # tflint-ignore: terraform_required_providers
  depends_on      = [restapi_object.configure_project]
  create_duration = "60s"
}
data "restapi_object" "get_project" {
  depends_on   = [resource.restapi_object.configure_project, resource.time_sleep.wait_60_seconds]
  provider     = restapi.restapi_watsonx_admin
  path         = "${local.dataplatform_api}/v2/projects"
  results_key  = "resources"
  search_key   = "metadata/guid"
  search_value = local.watsonx_project_id
  id_attribute = "metadata/guid"
}
*/

locals {
  dataplatform_api_mapping = {
    "us-south" = "//api.dataplatform.cloud.ibm.com",
    "eu-gb"    = "//api.eu-gb.dataplatform.cloud.ibm.com",
    "eu-de"    = "//api.eu-de.dataplatform.cloud.ibm.com",
    "jp-tok"   = "//api.jp-tok.dataplatform.cloud.ibm.com",
    "au-syd"   = "//api.au-syd.dai.cloud.ibm.com",
    "ca-tor"   = "//api.ca-tor.dai.cloud.ibm.com"
  }

  dataplatform_api          = local.dataplatform_api_mapping[local.watson_ml_instance_region]
  watsonx_project_id        = module.watson_ml_project.watsonx_ai_project_id
  watsonx_project_id_object = "/transactional/v2/projects/${local.watsonx_project_id}"
}
