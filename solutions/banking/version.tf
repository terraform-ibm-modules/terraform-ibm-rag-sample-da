terraform {
  # Lock DA into an exact provider version - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.87.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "2.0.1"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.13.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
  required_version = ">= 1.9.0"
}
