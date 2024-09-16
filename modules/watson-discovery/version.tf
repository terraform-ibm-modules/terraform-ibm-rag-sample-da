terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 1.19.1"
    }
  }
  required_version = ">= 1.3.0"
}
