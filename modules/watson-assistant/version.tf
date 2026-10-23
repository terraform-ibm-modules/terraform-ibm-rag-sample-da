terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.10"
    }
  }
  required_version = ">= 1.9.0"
}
