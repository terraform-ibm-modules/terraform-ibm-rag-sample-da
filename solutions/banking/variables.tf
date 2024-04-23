variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

variable "watsonx_admin_api_key" {
  default     = null
  description = "Used to call Watson APIs to configure the user and the project."
  sensitive   = true
  type        = string
}

variable "prefix" {
  description = "Prefix for resources to be created"
  type        = string
  default     = "rag-del-test"
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = true
}

variable "resource_group_name" {
  default     = "rag-del-resource-group"
  description = "Name of the IBM Cloud resource group in which resources should be created"
  type        = string
}

variable "toolchain_region" {
  description = "The region where the toolchains previously created reside"
  type        = string
  default     = "us-south"
}

variable "toolchain_resource_group" {
  description = "The resource group where the toolchains previously created reside"
  type        = string
  default     = "rag-del-resource-group"
}

variable "create_continuous_delivery_service_instance" {
  description = "Choose whether to install a Continuous Delivery service instance or not"
  type        = bool
  default     = false
}

variable "ci_pipeline_id" {
  description = "ID of the CI pipeline"
  type        = string
  default     = "fa63e4e9-1f19-4fbf-be10-261e9384921d"
}

variable "cd_pipeline_id" {
  description = "ID of the CD pipeline"
  type        = string
  default     = "3a1bc835-19fb-4fdb-8c47-78383380152b"
}

variable "inventory_repo_url" {
  description = "URL of the inventory repository"
  type        = string
  default     = null
}

variable "watson_assistant_instance_id" {
  description = "ID of the WatsonX Assistant service instance"
  type        = string
  default     = "9bdd9a67-995c-4a82-80ea-edc005a34d4e"
}

variable "watson_assistant_region" {
  description = "Region where WatsonX Assistant resides"
  type        = string
  default     = "us-south"
}

variable "watson_discovery_instance_id" {
  description = "ID of the WatsonX Discovery instance"
  type        = string
  default     = "b96e09cf-3d44-4a02-80e9-1762c613f1ca"
}

variable "watson_discovery_region" {
  description = "Region where Watson Discovery resides"
  type        = string
  default     = "us-south"
}

variable "watson_machine_learning_instance_crn" {
  description = "Watson Machine Learning instance CRN"
  type        = string
  default     = "crn:v1:bluemix:public:pm-20:us-south:a/abac0df06b644a9cabc6e44f55b3880e:85dd3375-b94a-4d02-abeb-867d1ca5b376::"
}

variable "watson_machine_learning_instance_guid" {
  description = "Watson Machine Learning instance GUID"
  type        = string
  default     = "85dd3375-b94a-4d02-abeb-867d1ca5b376"
}

variable "watson_machine_learning_instance_resource_name" {
  description = "Watson Machine Learning instance resource name"
  type        = string
  default     = "rag-del-watson-machine-learning-instance"
}

variable "signing_key" {
  description = "Signing GPG key."
  type        = string
  sensitive   = true
  default     = "abcd"
}

variable "secrets_manager_guid" {
  description = "Secrets Manager GUID where the API key and signing key will be stored."
  type        = string
  default     = "7c6e4f53-4ef5-46d4-8300-837282be943b"
}

variable "secrets_manager_region" {
  description = "The region where the Secrets Manager instance previously created reside."
  type        = string
  default     = "us-south"
}
