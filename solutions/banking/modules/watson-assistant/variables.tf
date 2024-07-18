variable "prefix" {
  description = "Prefix for resources to be created"
  type        = string
}

variable "watsonx_admin_api_key" {
  description = "API key to create resources with"
  type        = string
  sensitive = true
}

variable "watsonx_assistant_url" {
  description = "Watson Assistant instance endpoint"
  type        = string
}

variable "assistant_environment" {
  description = "Watson Assistant target environment"
  type        = string
  default = "draft"
}

variable "assistant_search_skill" {
  description = "Search skill configuration in JSON format"
  type        = string
  default = null
}

variable "assistant_action_skill" {
  description = "Action skill configuration in JSON format"
  type        = string
  default = null
}

variable "elastic_service_binding" {
  description = "Endpoint and credentials for Elastic instance"
  type = object({
    url      = string
    username = string
    password = string
    index    = string
  })
  default = null 
}