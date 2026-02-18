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

module "cos_kms_key_crn_parser" {
  count   = var.watsonx_project_delegated && var.cos_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.4.1"
  crn     = var.cos_kms_key_crn
}

data "ibm_resource_instance" "kms_instance" {
  provider   = ibm.ibm_resources
  count      = var.watsonx_project_delegated ? 1 : 0
  identifier = var.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].service_instance : var.cos_kms_crn
}

resource "ibm_kms_key" "cos_kms_key" {
  provider      = ibm.ibm_resources
  count         = var.watsonx_project_delegated && var.cos_kms_key_crn == null ? 1 : 0
  instance_id   = var.cos_kms_crn
  key_name      = var.cos_kms_new_key_name
  standard_key  = false
  force_delete  = true
  endpoint_type = try(jsondecode(data.ibm_resource_instance.kms_instance[0].parameters_json).allowed_network, "{}") == "private-only" ? "private" : "public"
  key_ring_id   = var.cos_kms_ring_id == null ? "default" : var.cos_kms_ring_id
}

moved {
  from = module.storage_delegation[0].ibm_kms_key.kms_key[0]
  to   = ibm_kms_key.cos_kms_key[0]
}

data "ibm_kms_key" "cos_kms_key" {
  provider      = ibm.ibm_resources
  count         = var.watsonx_project_delegated ? 1 : 0
  depends_on    = [resource.ibm_kms_key.cos_kms_key]
  endpoint_type = try(jsondecode(data.ibm_resource_instance.kms_instance[0].parameters_json).allowed_network, "{}") == "private-only" ? "private" : "public"
  instance_id   = var.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].service_instance : var.cos_kms_crn
  key_id        = var.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].resource : resource.ibm_kms_key.cos_kms_key[0].key_id
}

locals {
  effective_cos_kms_key_crn = var.watsonx_project_delegated ? data.ibm_kms_key.cos_kms_key[0].keys[0].crn : null
}

module "storage_delegation" {
  source  = "terraform-ibm-modules/watsonx-ai/ibm//modules/storage_delegation"
  version = "2.15.0"
  count   = var.watsonx_project_delegated ? 1 : 0
  providers = {
    ibm     = ibm.ibm_resources
    restapi = restapi.restapi_watsonx_admin
  }
  cos_kms_key_crn               = local.effective_cos_kms_key_crn
  cos_instance_guid             = module.cos.cos_instance_guid
  skip_iam_authorization_policy = var.skip_iam_authorization_policy
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

module "configure_project" {
  source  = "terraform-ibm-modules/watsonx-ai/ibm//modules/configure_project"
  version = "2.15.0"
  providers = {
    restapi = restapi.restapi_watsonx_admin
  }

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
  to   = module.configure_project.restapi_object.configure_project
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
