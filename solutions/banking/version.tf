terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.66.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.2"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 1.19.1"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.7"
    }
  }
  required_version = ">= 1.3.0"
}
