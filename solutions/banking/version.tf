terraform {
  # Lock DA into an exact provider version - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "2.2.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
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
      version = "0.15.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
  required_version = ">= 1.9.0"
}
