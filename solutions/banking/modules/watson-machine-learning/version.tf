terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.67.1"
      configuration_aliases = [ ibm.ibm_resources ]
    }
    restapi = {
      source                = "Mastercard/restapi"
      version               = ">= 1.19.1"
      configuration_aliases = [restapi.restapi_watsonx_admin]
    }    
  }
  required_version = ">= 1.3.0"
}
