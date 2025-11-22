terraform {
  # Lock DA into an exact provider version - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.85.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
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
      version = "0.12.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
  required_version = ">= 1.9.0"
}
