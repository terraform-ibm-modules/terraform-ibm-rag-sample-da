terraform {
  required_providers {
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
  }
  required_version = ">= 1.9.0"
}
