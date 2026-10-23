##############################################################################################################
# Cloud Object Storage
##############################################################################################################

module "cos" {
  providers = {
    ibm = ibm.ibm_resources
  }
  source            = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version           = "10.17.15"
  resource_group_id = var.resource_group_id
  cos_instance_name = var.cos_instance_name
  cos_plan          = "standard"
}

##############################################################################################################
# CRN PARSERS
##############################################################################################################

module "cos_kms_key_crn_parser" {
  count   = var.watsonx_project_delegated && var.cos_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.9.0"
  crn     = var.cos_kms_key_crn
}

module "cos_kms_crn_parser" {
  count   = var.watsonx_project_delegated && var.cos_kms_key_crn == null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.9.0"
  crn     = var.cos_kms_crn
}

data "ibm_resource_instance" "kms_instance" {
  provider   = ibm.ibm_resources
  count      = var.watsonx_project_delegated ? 1 : 0
  identifier = var.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].service_instance : var.cos_kms_crn
}

##############################################################################################################
# KMS Endpoint Configuration
##############################################################################################################

locals {
  kms_allowed_network = var.watsonx_project_delegated ? try(jsondecode(data.ibm_resource_instance.kms_instance[0].parameters_json).allowed_network, "public-only") : "public-only"
  kms_endpoint_type   = local.kms_allowed_network == "private-only" ? "private" : "public"
}

resource "ibm_kms_key" "cos_kms_key" {
  provider      = ibm.ibm_resources
  count         = var.watsonx_project_delegated && var.cos_kms_key_crn == null ? 1 : 0
  instance_id   = var.cos_kms_crn
  key_name      = var.cos_kms_new_key_name
  standard_key  = false
  force_delete  = true
  endpoint_type = local.kms_endpoint_type
  key_ring_id   = var.cos_kms_ring_id == null ? "default" : var.cos_kms_ring_id
}

moved {
  from = module.storage_delegation[0].ibm_kms_key.kms_key[0]
  to   = ibm_kms_key.cos_kms_key[0]
}

data "ibm_kms_key" "cos_kms_key" {
  provider      = ibm.ibm_resources
  count         = var.watsonx_project_delegated ? 1 : 0
  endpoint_type = local.kms_endpoint_type
  # Resolve the key identity for both modes:
  # - If cos_kms_key_crn is provided, use parser outputs from that CRN.
  # - If cos_kms_key_crn is null, use the key created by ibm_kms_key.cos_kms_key.
  instance_id = var.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].service_instance : var.cos_kms_crn
  key_id      = var.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].resource : resource.ibm_kms_key.cos_kms_key[0].key_id
}

locals {
  kms_key_crn = var.watsonx_project_delegated ? data.ibm_kms_key.cos_kms_key[0].keys[0].crn : null
}

##############################################################################################################
# Storage Delegation
##############################################################################################################

# The watsonx-ai storage_delegation and configure_project submodules need the Mastercard/restapi provider,
# so their logic is inlined here. The http provider only has a data source and cannot create or delete
# objects, so the project and delegation lifecycle is handled by curl calls in scripts/watsonx-utils.sh.

module "kms_key_crn_parser" {
  count   = var.watsonx_project_delegated ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.9.0"
  crn     = local.kms_key_crn
}

locals {
  kms_key_region              = var.watsonx_project_delegated ? module.kms_key_crn_parser[0].region : null
  kms_service                 = var.watsonx_project_delegated ? module.kms_key_crn_parser[0].service_name : null
  kms_account_id              = var.watsonx_project_delegated ? module.kms_key_crn_parser[0].account_id : null
  kms_key_id                  = var.watsonx_project_delegated ? module.kms_key_crn_parser[0].resource : null
  target_resource_instance_id = var.watsonx_project_delegated ? module.kms_key_crn_parser[0].service_instance : null

  storage_delegation_body = var.watsonx_project_delegated ? jsonencode({
    cos_instance_id = module.cos.cos_instance_guid
    kms_key_crn     = local.kms_key_crn
    catalogs        = true
    projects        = true
  }) : null
}

resource "ibm_iam_authorization_policy" "cos_s2s_keyprotect" {
  provider                    = ibm.ibm_resources
  count                       = var.watsonx_project_delegated && !var.skip_iam_authorization_policy ? 1 : 0
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = module.cos.cos_instance_guid
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.target_resource_instance_id
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
  roles = ["Reader"]
}

moved {
  from = module.storage_delegation[0].ibm_iam_authorization_policy.cos_s2s_keyprotect[0]
  to   = ibm_iam_authorization_policy.cos_s2s_keyprotect[0]
}

resource "time_sleep" "wait_for_authorization_policy" {
  count      = var.watsonx_project_delegated ? 1 : 0
  depends_on = [ibm_iam_authorization_policy.cos_s2s_keyprotect]
  # workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
  create_duration = "30s"
  # workaround for https://github.com/terraform-ibm-modules/terraform-ibm-cos/issues/672
  destroy_duration = "30s"
}

moved {
  from = module.storage_delegation[0].time_sleep.wait_for_authorization_policy
  to   = time_sleep.wait_for_authorization_policy[0]
}

resource "shell_script" "storage_delegation" {
  count      = var.watsonx_project_delegated ? 1 : 0
  depends_on = [time_sleep.wait_for_authorization_policy]

  lifecycle_commands {
    create = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      create_storage_delegation
    EOT
    read   = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      read_storage_delegation
    EOT
    update = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      update_storage_delegation
    EOT
    delete = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      delete_storage_delegation
    EOT
  }

  environment = {
    DATAPLATFORM_UI_URL     = local.dataplatform_ui_mapping[local.kms_key_region]
    COS_INSTANCE_GUID       = module.cos.cos_instance_guid
    STORAGE_DELEGATION_BODY = local.storage_delegation_body
  }

  sensitive_environment = {
    IBMCLOUD_API_KEY = var.ibmcloud_api_key
  }

  # Change in apikey should not trigger re-create
  lifecycle {
    ignore_changes = [sensitive_environment]
  }
}

# Drop the old restapi object from state without calling its destroy. The create
# script adopts the existing delegation of the COS instance.
removed {
  from = module.storage_delegation.restapi_object.storage_delegation
  lifecycle {
    destroy = false
  }
}

# parse the crn for region and guid
module "crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.9.0"
  crn     = var.watson_ml_instance_crn
}

locals {
  watson_ml_instance_guid   = module.crn_parser.service_instance
  watson_ml_instance_region = module.crn_parser.region
}

# Wait for Watson Studio backend to register storage delegation
resource "time_sleep" "wait_for_storage_delegation_backend" {
  count           = var.watsonx_project_delegated ? 1 : 0
  depends_on      = [shell_script.storage_delegation]
  create_duration = "10m"
}

##############################################################################################################
# Configure Project
##############################################################################################################

locals {
  dataplatform_api_mapping = {
    "us-south" = "https://api.dataplatform.cloud.ibm.com",
    "eu-gb"    = "https://api.eu-gb.dataplatform.cloud.ibm.com",
    "eu-de"    = "https://api.eu-de.dataplatform.cloud.ibm.com",
    "jp-tok"   = "https://api.jp-tok.dataplatform.cloud.ibm.com",
    "au-syd"   = "https://api.au-syd.dai.cloud.ibm.com",
    "ca-tor"   = "https://api.ca-tor.dai.cloud.ibm.com"
  }
  dataplatform_ui_mapping = {
    "us-south" = "https://dataplatform.cloud.ibm.com",
    "eu-gb"    = "https://eu-gb.dataplatform.cloud.ibm.com",
    "eu-de"    = "https://eu-de.dataplatform.cloud.ibm.com",
    "jp-tok"   = "https://jp-tok.dataplatform.cloud.ibm.com",
    "au-syd"   = "https://au-syd.dai.cloud.ibm.com",
    "ca-tor"   = "https://ca-tor.dai.cloud.ibm.com"
  }
  dataplatform_api = local.dataplatform_api_mapping[local.watson_ml_instance_region]
  dataplatform_ui  = local.dataplatform_ui_mapping[local.watson_ml_instance_region]

  watsonx_project_compute = [{
    name = var.watson_ml_instance_resource_name
    guid = local.watson_ml_instance_guid
    type = "machine_learning"
    crn  = var.watson_ml_instance_crn
  }]

  watsonx_project_create_body = jsonencode({
    name      = var.watson_ml_project_name
    generator = "terraform-ibm-rag-sample-da"
    type      = "wx"
    storage = {
      type         = "bmcos_object_storage"
      guid         = module.cos.cos_instance_guid
      resource_crn = module.cos.cos_instance_crn
      delegated    = var.watsonx_project_delegated
    }
    description = var.watson_ml_project_description
    public      = true
    tags        = var.watson_ml_project_tags
    compute     = local.watsonx_project_compute
    settings = {
      access_restrictions = {
        data = var.watson_ml_project_sensitive
      }
    }
  })

  watsonx_project_update_body = jsonencode({
    name        = var.watson_ml_project_name
    type        = "wx"
    description = var.watson_ml_project_description
    public      = true
    compute     = [for c in local.watsonx_project_compute : merge(c, { credentials = {} })]
  })

  watsonx_project_id = shell_script.configure_project.output.project_id
}

resource "shell_script" "configure_project" {
  depends_on = [shell_script.storage_delegation, time_sleep.wait_for_storage_delegation_backend]

  lifecycle_commands {
    create = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      create_project
    EOT
    read   = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      read_project
    EOT
    update = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      update_project
    EOT
    delete = <<-EOT
      set -e
      source ./${path.module}/scripts/watsonx-utils.sh
      delete_project
    EOT
  }

  environment = {
    DATAPLATFORM_API_URL = local.dataplatform_api
    PROJECT_NAME         = var.watson_ml_project_name
    PROJECT_CREATE_BODY  = local.watsonx_project_create_body
    PROJECT_UPDATE_BODY  = local.watsonx_project_update_body
  }

  sensitive_environment = {
    IBMCLOUD_API_KEY = var.ibmcloud_api_key
  }

  lifecycle {
    ignore_changes = [sensitive_environment]
  }
}

# Drop the old restapi object from state without calling its destroy. The create
# script adopts the existing project by name.
removed {
  from = module.configure_project.restapi_object.configure_project
  lifecycle {
    destroy = false
  }
}

# Read the project back with the http provider (bucket name and other details)
data "http" "get_project" {
  url = "${local.dataplatform_api}/v2/projects/${local.watsonx_project_id}"
  request_headers = {
    Authorization  = var.sensitive_tokendata
    "Content-Type" = "application/json"
  }

  retry {
    attempts     = 3
    min_delay_ms = 5000
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Reading the watsonx.ai project failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}

locals {
  watsonx_project_data = jsondecode(data.http.get_project.response_body)
}

resource "null_resource" "add_collaborators_to_project" {
  for_each = { for member in var.watsonx_ai_new_project_members : member.email => member }
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command     = "${path.module}/scripts/add_collaborators_to_project.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      iam_token  = var.sensitive_tokendata
      region     = local.watson_ml_instance_region
      project_id = local.watsonx_project_id
      user_name  = each.value.email
      iam_id     = each.value.iam_id
      role       = each.value.role
      state      = each.value.state
      type       = each.value.type
    }
  }
}
