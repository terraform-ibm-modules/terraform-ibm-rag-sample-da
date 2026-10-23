terraform {
  required_providers {
    ibm = {
      source                = "IBM-Cloud/ibm"
      version               = ">= 1.67.1"
      configuration_aliases = [ibm.ibm_resources]
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.10"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
  required_version = ">= 1.9.0"
}
