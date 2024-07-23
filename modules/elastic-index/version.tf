terraform {
  required_providers {
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.10"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = ">= 0.11.0"
    }
  }
  required_version = ">= 1.3.0"
}
