variable "watsonx_assistant_id" {
  description = "Watson Assistant instance ID"
  type        = string
  default = null
}

variable "assistant_environment_id" {
  description = "Watson Assistant environment ID"
  type        = string
  default     = null
}

variable "assistant_search_skill_id" {
  description = "Search skill configuration ID"
  type        = string
  default     = null
}

variable "assistant_action_skill_id" {
  description = "Action skill configuration ID"
  type        = string
  default     = null
}


variable "existing_access_group_name" {
  description = "Access group to add policies to"
  type        = string
  default     = null
}
