########################################################################################################################
# Provider config
########################################################################################################################

provider "ibm" {
  alias            = "watson_assistance"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.watson_assistant_region
}

provider "ibm" {
  alias            = "watson_discovery"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.watson_discovery_region
}
