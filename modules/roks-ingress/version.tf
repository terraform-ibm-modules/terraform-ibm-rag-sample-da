terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.67.1"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.10"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.1"
    }
  }
  required_version = ">= 1.9.0"
}
