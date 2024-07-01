output "watsonx_project_id" {
  description = "ID of the created WatsonX project."
  value       = module.configure_project.watsonx_project_id
}

output "watsonx_project_url" {
  description = "WatsonX project ID URL."
  value       = "https://dataplatform.cloud.ibm.com/projects/${module.configure_project.watsonx_project_id}"
}

output "watsonx_assistant_api_url" {
  description = "WatsonX Assistant URL."
  value       = local.watsonx_assistant_url
}

output "watson_discovery_api_url" {
  description = "Watson Discovery URL."
  value       = "https:${local.watson_discovery_url}"
}

output "cos_instance_crn" {
  description = "COS instance CRN which is configured with the WatsonX project."
  value       = module.cos.cos_instance_crn
}

output "watsonx_assistant_integration_id" {
  description = "WatsonX assistant integration ID."
  value       = shell_script.watson_assistant.output["assistant_integration_id"]
}

output "watson_discovery_project_id" {
  description = "Watson Discovery Project ID."
  value       = restapi_object.configure_discovery_project.id
}
