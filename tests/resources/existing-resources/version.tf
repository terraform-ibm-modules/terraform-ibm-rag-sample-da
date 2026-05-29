terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.53.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}
