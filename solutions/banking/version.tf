terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = ">=2.3.3"
    }
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.64.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.1"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 1.19.1"
    }
  }
  required_version = ">= 1.3.0"
}
