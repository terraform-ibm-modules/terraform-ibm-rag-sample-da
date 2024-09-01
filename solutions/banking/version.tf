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
      version = ">= 1.20.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.10"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = ">= 0.11.6"
    }
  }
  required_version = ">= 1.3.0"
}
