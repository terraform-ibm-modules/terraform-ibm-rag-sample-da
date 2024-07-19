variable "watson_discovery_url" {
  description = "WatsonX Discovery URL"
  type        = string
}

variable "watson_discovery_project_name" {
  description = "Watson Discovery project name"
  type        = string
}

variable "watson_discovery_collection_name" {
  description = "Watson Discovery collection name"
  type        = string
}

variable "watson_discovery_collection_artifacts_path" {
  description = "Local directory with artifacts to upload"
  type        = string
  default     = null
}

variable "sensitive_tokendata" {
  description = "Access token"
  type        = string
  sensitive   = true
}
