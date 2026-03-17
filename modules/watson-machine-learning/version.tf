terraform {
  required_providers {
    ibm = {
      source                = "IBM-Cloud/ibm"
      version               = ">= 1.67.1"
      configuration_aliases = [ibm.ibm_resources]
    }
    restapi = {
      source                = "Mastercard/restapi"
      version               = ">= 1.19.1"
      configuration_aliases = [restapi.restapi_watsonx_admin]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }
  required_version = ">= 1.9.0"
}
