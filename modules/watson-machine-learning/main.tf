# create COS instance for WatsonX.AI project
module "cos" {
  providers = {
    ibm = ibm.ibm_resources
  }
  source            = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version           = "8.15.10"
  resource_group_id = var.resource_group_id
  cos_instance_name = var.cos_instance_name
  cos_plan          = "standard"
}

module "storage_delegation" {
  providers = {
    ibm                           = ibm
    ibm.deployer                  = ibm
    restapi.restapi_watsonx_admin = restapi.restapi_watsonx_admin
  }
  source               = "git::https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-saas-da.git//storage_delegation?ref=v1.8.1"
  count                = var.watsonx_project_delegated ? 1 : 0
  cos_kms_crn          = var.cos_kms_crn
  cos_kms_key_crn      = var.cos_kms_key_crn
  cos_kms_new_key_name = var.cos_kms_new_key_name
  cos_kms_ring_id      = var.cos_kms_ring_id
  cos_guid             = module.cos.cos_instance_guid
}

## Use code from Watson SaaS directly to avoid "legacy module" issues
## Note: passing a non-null delegated storage attribute may result in API errors

resource "restapi_object" "configure_project" {
  depends_on     = [module.storage_delegation]
  provider       = restapi.restapi_watsonx_admin
  path           = local.dataplatform_api
  read_path      = "${local.dataplatform_api}{id}"
  read_method    = "GET"
  create_path    = "${local.dataplatform_api}/transactional/v2/projects?verify_unique_name=true"
  create_method  = "POST"
  id_attribute   = "location"
  destroy_method = "DELETE"
  destroy_path   = "${local.dataplatform_api}/transactional{id}"
  data = <<-EOT
                  {
                    "name": "${var.watson_ml_project_name}",
                    "generator": "watsonx-saas-da",
                    "type": "wx",
                    "storage": {
                      "type": "bmcos_object_storage",
                      "guid": "${module.cos.cos_instance_guid}",
                      ${var.watsonx_project_delegated == true ? "\"delegated\": true," : ""}
                      "resource_crn": "${module.cos.cos_instance_crn}"
                    },
                    "description": "${var.watson_ml_project_description}",
                    "public": true,
                    "tags": ${jsonencode(var.watson_ml_project_tags)},${
var.watson_ml_project_sensitive ? "\"settings\": {\"access_restrictions\":  {\"data\": true} }," : ""}
                    "compute": [
                      {
                        "name": "${var.watson_ml_instance_resource_name}",
                        "guid": "${var.watson_ml_instance_guid}",
                        "type": "machine_learning",
                        "crn": "${var.watson_ml_instance_crn}"
                      }
                    ]
                  }
                  EOT
update_method = "PATCH"
update_path   = "${local.dataplatform_api}{id}"
update_data   = <<-EOT
                  {
                    "name": "${var.watson_ml_project_name}",
                    "type": "wx",
                    "description": "${var.watson_ml_project_description}",
                    "public": true,
                    "compute": [
                      {
                        "name": "${var.watson_ml_instance_resource_name}",
                        "guid": "${var.watson_ml_instance_guid}",
                        "type": "machine_learning",
                        "crn": "${var.watson_ml_instance_crn}",
                        "credentials": { }
                      }
                    ]
                  }
                  EOT
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
    "eu-gb"    = "//api.eu-uk.dataplatform.cloud.ibm.com",
    "eu-de"    = "//api.eu-de.dataplatform.cloud.ibm.com",
    "jp-tok"   = "//api.jp-tok.dataplatform.cloud.ibm.com"
  }

  dataplatform_api          = local.dataplatform_api_mapping[var.location]
  watsonx_project_id_object = restapi_object.configure_project.id
  watsonx_project_id        = regex("^.+/([a-f0-9\\-]+)$", local.watsonx_project_id_object)[0]
}
