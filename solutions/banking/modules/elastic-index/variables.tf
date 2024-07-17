variable "elastic_instance_crn" {
  description = "Elastic ICD instance CRN"
  type        = string
  default     = null   # Elastic usage is optional
}

variable "elastic_credentials_name" {
  description = "Name of service credentials used to access Elastic instance"
  type        = string
  default     = "toolchain_db_user"
}

variable "elastic_index_name" {
  description = "Name of index in Elastic instance"
  type        = string
  default     = "sample-rag-app-content"
}

variable "collection_artifacts_path" {
  description = "Local directory with artifacts to upload"
  type        = string
  default = null
}

variable "sensitive_tokendata" {
  description = "Access token"
  type        = string
  sensitive = true
}
