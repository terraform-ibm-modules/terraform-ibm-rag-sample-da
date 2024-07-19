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

variable "elastic_index_entries_file" {
  description = "Path to JSON file with content entries"
  type        = string
  default     = null
}
