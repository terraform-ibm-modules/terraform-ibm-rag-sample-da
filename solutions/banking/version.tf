terraform {
  # Lock DA into an exact provider version - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "2.0.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "3.0.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.14.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
  }
  required_version = ">= 1.9.0"
}
