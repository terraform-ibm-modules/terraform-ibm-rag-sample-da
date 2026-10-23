
output "watsonx_assistant_id" {
  value       = shell_script.watson_assistant.output.assistant_id
  description = "The ID of watsonx assistant that's created."
}

output "watsonx_assistant_integration_id" {
  value       = shell_script.watson_assistant.output.assistant_integration_id
  description = "The Integration ID of watsonx assistant that's created."
}

output "watsonx_assistant_environment" {
  value       = local.watsonx_assistant_environment_after_update
  description = "Assistant environment."
}

output "watsonx_assistant_skills_status" {
  value = {
    action = var.assistant_action_skill != null ? jsondecode(data.http.assistant_action_skill[0].response_body) : null
    search = var.assistant_search_skill != null ? jsondecode(data.http.assistant_search_skill[0].response_body) : null
  }
  description = "Assistant skills status."
}
