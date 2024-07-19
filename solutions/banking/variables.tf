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

variable "inventory_repo_url" {
  description = "URL of the inventory repository"
  type        = string
  default     = null
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
  default     = null # Discovery usage is optional, elastic can be used instead
}

variable "watson_discovery_region" {
  description = "Region where Watson Discovery resides"
  type        = string
  default     = null # Discovery usage is optional, elastic can be used instead
}

variable "watson_machine_learning_instance_crn" {
  description = "Watson Machine Learning instance CRN"
  type        = string
  default     = null # WML usage is optional, elastic can be used instead
}

variable "watson_machine_learning_instance_guid" {
  description = "Watson Machine Learning instance GUID"
  type        = string
  default     = null # WML usage is optional, elastic can be used instead
}

variable "watson_machine_learning_instance_resource_name" {
  description = "Watson Machine Learning instance resource name"
  type        = string
  default     = null # WML usage is optional, elastic can be used instead
}

variable "elastic_instance_crn" {
  description = "Elastic ICD instance CRN"
  type        = string
  default     = null # Elastic usage is optional
}

variable "elastic_credentials_name" {
  description = "Name of service credentials used to access Elastic instance"
  type        = string
  default     = "wxasst_db_user"
}

variable "elastic_index_name" {
  description = "Name of index in Elastic instance"
  type        = string
  default     = "sample-rag-app-content"
}

variable "elastic_upload_sample_data" {
  description = "Upload sample artifacts to elastic index"
  type        = bool
  default     = true
}

variable "signing_key" {
  description = "Signing GPG key."
  type        = string
  sensitive   = true
}

variable "create_secrets" {
  description = "Create Secrets in the existing Secrets Manager instance."
  type        = bool
  default     = true
}

variable "secrets_manager_endpoint_type" {
  type        = string
  description = "The endpoint type to communicate with the provided secrets manager instance. Possible values are `public` or `private`"
  default     = "private"
}

variable "secrets_manager_guid" {
  description = "Secrets Manager GUID where the API key and signing key will be stored."
  type        = string
}

variable "secrets_manager_region" {
  description = "The region where the Secrets Manager instance previously created reside."
  type        = string
}

variable "trigger_ci_pipeline_run" {
  description = "Whether to trigger the CI pipeline to build and deploy the application when deploying this solution"
  type        = bool
  default     = true
}
