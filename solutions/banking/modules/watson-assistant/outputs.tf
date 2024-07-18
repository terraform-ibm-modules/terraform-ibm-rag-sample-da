
output "watsonx_assistant_id" {
  value       = shell_script.watson_assistant.output.assistant_id
  description = "The ID of watsonx assistant that's created."
}

output "watsonx_assistant_integration_id" {
  value       = shell_script.watson_assistant.output.assistant_integration_id
  description = "The Integration ID of watsonx assistant that's created."
}

output "watsonx_assistant_environment" {
  value       =  jsondecode(data.restapi_object.get_assistant_environment_after_update.api_response)
  description = "Assistant environment."
}

output "watsonx_assistant_skills_status" {
  value       =  { 
      action = var.assistant_action_skill != null ? jsondecode(restapi_object.assistant_action_skill[0].api_response) : null
      search = var.assistant_search_skill != null ? jsondecode(restapi_object.assistant_search_skill[0].api_response) : null
  }
  description = "Assistant skills status."
}