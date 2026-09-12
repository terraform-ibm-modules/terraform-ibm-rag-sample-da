terraform {
  # Lock DA into an exact provider version - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "2.6.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
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
      version = "0.16.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.14.2"
    }
  }
  required_version = ">= 1.9.0"
}
