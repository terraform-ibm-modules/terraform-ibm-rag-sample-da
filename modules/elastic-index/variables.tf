variable "elastic_service_binding" {
  description = "Elastic ICD instance credentials"
  type = object({
    url            = string
    username       = string
    password       = string
    ca_data_base64 = optional(string)
  })
}

variable "elastic_index_name" {
  description = "Name of index in Elastic instance"
  type        = string
  default     = "sample-rag-app-content"
}

variable "elastic_index_mapping" {
  description = "Mapping configuration for the Elastic index"
  type        = string
  default     = "{}"
}

variable "elastic_index_entries_file" {
  description = "Path to JSON file with content entries"
  type        = string
  default     = null
}
