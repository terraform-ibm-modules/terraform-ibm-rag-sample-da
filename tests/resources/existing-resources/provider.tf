########################################################################################################################
# Provider config
########################################################################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

# provider "elasticsearch" {
#   username    = module.icd_elasticsearch.service_credentials_object.credentials["elasticsearch_admin"].username
#   password    = module.icd_elasticsearch.service_credentials_object.credentials["elasticsearch_admin"].password
#   url         = "https://${module.icd_elasticsearch.service_credentials_object.hostname}:${module.icd_elasticsearch.service_credentials_object.port}"
#   cacert_file = base64decode(module.icd_elasticsearch.service_credentials_object.certificate)
# }
