terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.67.1"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.10"
    }
  }
  required_version = ">= 1.3.0"
}
