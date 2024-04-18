variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

variable "watsonx_admin_api_key" {
  default     = null
  description = "Used to call Watson APIs to configure the user and the project"
  sensitive   = true
  type        = string
}

variable "prefix" {
  description = "Prefix for resources to be created"
  type        = string
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  default     = null
  description = "Name of the IBM Cloud resource group in which resources should be created"
  type        = string
}

variable "toolchain_region" {
  description = "The region where the toolchains previously created reside"
  type        = string
}

variable "toolchain_resource_group" {
  description = "The resource group where the toolchains previously created reside"
  type        = string
}

variable "create_continuous_delivery_service_instance" {
  description = "Choose whether to install a Continuous Delivery service instance or not"
  type        = bool
  default     = true
}

variable "ci_pipeline_id" {
  description = "ID of the CI pipeline"
  type        = string
}

variable "cd_pipeline_id" {
  description = "ID of the CD pipeline"
  type        = string
}

variable "watson_assistant_instance_id" {
  description = "ID of the WatsonX Assistant service instance"
  type        = string
}

variable "watson_assistant_region" {
  description = "Region where WatsonX Assistant resides"
  type        = string
}

variable "watson_discovery_instance_id" {
  description = "ID of the WatsonX Discovery instance"
  type        = string
}

variable "watson_discovery_region" {
  description = "Region where Watson Discovery resides"
  type        = string
}

variable "watson_machine_learning_instance_crn" {
  description = "Watson Machine Learning instance CRN"
  type        = string
}

variable "watson_machine_learning_instance_guid" {
  description = "Watson Machine Learning instance GUID"
  type        = string
}

variable "watson_machine_learning_instance_resource_name" {
  description = "Watson Machine Learning instance resource name"
  type        = string
}
