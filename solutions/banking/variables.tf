variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

variable "toolchain_region" {
  description = "The region where the toolchains previously created reside"
  type        = string
  default     = null
}

variable "ci_pipeline_id" {
  description = "ID of the CI pipeline"
  type        = string
  default     = null
}

variable "cd_pipeline_id" {
  description = "ID of the CD pipeline"
  type        = string
  default     = null
}

variable "watson_assistant_instance_id" {
  description = "ID of the WatsonX Assistant service instance"
  type        = string
  default     = null
}

variable "watson_assistant_region" {
  description = "Region where WatsonX Assistant resides"
  type        = string
  default     = null
}

variable "watson_discovery_instance_id" {
  description = "ID of the WatsonX Discovery instance"
  type        = string
  default     = null
}

variable "watson_discovery_region" {
  description = "Region where Watson Discovery resides"
  type        = string
  default     = null
}

# to be used later
# variable "resource_group_name" {
#   default     = null
#   description = "Name of the IBM Cloud resource group in which resources should be created"
#   type        = string
# }
