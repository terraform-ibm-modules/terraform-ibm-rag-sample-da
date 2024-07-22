provider "ibm" {
  alias            = "ibm_resources"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.toolchain_region
}

provider "ibm" {
  alias            = "sm_resources"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.secrets_manager_region
}

provider "ibm" {
  ibmcloud_api_key = var.watsonx_admin_api_key != null ? var.watsonx_admin_api_key : var.ibmcloud_api_key
  region           = var.toolchain_region
}

provider "restapi" {
  uri                  = "https:"
  write_returns_object = true
  debug                = true
  headers = {
    Authorization = data.ibm_iam_auth_token.tokendata.iam_access_token
    Content-Type  = "application/json"
  }
}

provider "restapi" {
  alias                = "restapi_watsonx_admin"
  uri                  = "https:"
  write_returns_object = true
  debug                = true
  headers = {
    Authorization = data.ibm_iam_auth_token.tokendata.iam_access_token
    Content-Type  = "application/json"
  }
}

provider "shell" {
  interpreter        = ["/bin/bash", "-c"]
  enable_parallelism = false
}

provider "elasticstack" {
  elasticsearch {
    username  = local.use_elastic_index ? local.elastic_service_binding.username : ""
    password  = local.use_elastic_index ? local.elastic_service_binding.password : ""
    endpoints = local.use_elastic_index ? [local.elastic_service_binding.url] : []
    ca_data   = local.use_elastic_index ? base64decode(local.elastic_service_binding.ca_data_base64) : null
  }
}
