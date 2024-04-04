terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = ">=2.3.3"
    }
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.53.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }
  required_version = ">= 1.3.0"
}
