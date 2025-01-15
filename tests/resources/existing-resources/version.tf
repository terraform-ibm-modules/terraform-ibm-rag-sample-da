terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.53.0"
    }
    # The elasticsearch provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    # elasticsearch = {
    #   source  = "phillbaker/elasticsearch"
    #   version = ">= 2.0.7"
    # }
    # null = {
    #   source  = "hashicorp/null"
    #   version = ">= 3.2.1, < 4.0.0"
    # }
    # time = {
    #   source  = "hashicorp/time"
    #   version = ">= 0.9.1"
    # }
  }
}
