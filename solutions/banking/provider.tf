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

provider "restapi" {
  alias                 = "oc_api"
  uri                   = "https://containers.cloud.ibm.com/global"
  write_returns_object  = true
  create_returns_object = true

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

##############################################################################
# Init cluster config for kubernetes provider
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  count           = var.cluster_name != null ? 1 : 0
  cluster_name_id = var.cluster_name
  admin           = true
  endpoint_type   = "private"
}

##############################################################################
# Config providers
##############################################################################


provider "kubernetes" {
  host                   = var.cluster_name != null ? data.ibm_container_cluster_config.cluster_config[0].host : ""
  client_certificate     = var.cluster_name != null ? data.ibm_container_cluster_config.cluster_config[0].admin_certificate : ""
  client_key             = var.cluster_name != null ? data.ibm_container_cluster_config.cluster_config[0].admin_key : ""
  cluster_ca_certificate = var.cluster_name != null ? data.ibm_container_cluster_config.cluster_config[0].ca_certificate : ""
}
