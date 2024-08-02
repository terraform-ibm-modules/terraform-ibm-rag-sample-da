variable "resource_group_id" {
  description = "Resource group for Watson ML COS instance"
  type        = string
}

variable "cos_instance_name" {
  description = "Watson ML COS instance name"
  type        = string
}

variable "cos_kms_crn" {
  description = "KMS service instance CRN used to encrypt the COS buckets used by the watsonx projects."
  type        = string
  default     = null

  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}kms:(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.cos_kms_crn)),
      var.cos_kms_crn == null,
    ])
    error_message = "Key Protect CRN validation failed."
  }
}

variable "cos_kms_key_crn" {
  description = "KMS key CRN used to encrypt the COS buckets used by the watsonx projects. If not set, then the cos_kms_new_key_name must be specified."
  type        = string
  default     = null
}

variable "cos_kms_new_key_name" {
  description = "Name of the KMS key to create for encrypting the COS buckets used by the watsonx projects."
  type        = string
}

variable "cos_kms_ring_id" {
  description = "The identifier of the KMS ring to create the cos_kms_new_key_name into. If it is not set, then the new key will be created in the default ring."
  type        = string
  default     = null
}

variable "watson_ml_instance_crn" {
  description = "Watson Machine Learning instance CRN"
  type        = string
}

variable "watson_ml_instance_guid" {
  description = "Watson Machine Learning instance GUID"
  type        = string
}

variable "watson_ml_instance_resource_name" {
  description = "Watson Machine Learning instance resource name"
  type        = string
}

variable "watson_ml_project_name" {
  description = "Watson Machine Learning project name"
  type        = string
}

variable "watson_ml_project_description" {
  description = "Watson Machine Learning project description"
  type        = string
  default     = "WatsonX AI project for RAG pattern sample app"
}

variable "watson_ml_project_tags" {
  description = "Watson Machine Learning project tags"
  type        = list(string)
  default     = ["watsonx-ai-SaaS", "RAG-sample-project"]
}

variable "location" {
  description = "The location that's used with the IBM Cloud Terraform IBM provider. It's also used during resource creation."
  type        = string
}

variable "watsonx_project_delegated" {
  description = "Watson storage delegation."
  type        = bool
  default     = null
}
