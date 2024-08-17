terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.68.1"
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
      version = ">= 1.7.10"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = ">= 0.11.5"
    }
  }
  required_version = ">= 1.3.0"
}
