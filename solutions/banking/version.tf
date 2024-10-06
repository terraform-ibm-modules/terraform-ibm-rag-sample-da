terraform {
  # Lock DA into an exact provider version - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.70.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "1.20.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.11.8"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
  required_version = ">= 1.3.0"
}
