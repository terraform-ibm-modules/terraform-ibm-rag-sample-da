variable "resource_group_id" {
  description = "Resource group for Watson ML COS instance"
  type        = string
}

variable "cos_instance_name" {
  description = "Watson ML COS instance name"
  type        = string
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
