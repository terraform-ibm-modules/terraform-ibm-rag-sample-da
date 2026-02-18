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

variable "watson_ml_instance_resource_name" {
  description = "Watson Machine Learning instance resource name"
  type        = string
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Whether to create an IAM authorization policy that permits the Object Storage instance to read the encryption key from the KMS instance. An authorization policy must exist before an encrypted bucket can be created. Set to `true` to avoid creating the policy."
  default     = false
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

variable "watson_ml_project_sensitive" {
  description = "Mark Watson project as sensitive"
  type        = bool
  default     = false
}

variable "watsonx_project_delegated" {
  description = "Watson storage delegation."
  type        = bool
  default     = null
}
