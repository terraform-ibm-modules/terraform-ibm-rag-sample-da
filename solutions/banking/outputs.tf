output "watsonx_project_id" {
  description = "ID of the created WatsonX project."
  value       = module.configure_project.project_id
}

output "watsonx_project_url" {
  description = "WatsonX project ID URL."
  value       = "https://dataplatform.cloud.ibm.com/projects/${module.configure_project.project_id}"
}

output "watsonx_assistant_api_url" {
  description = "WatsonX Assistant URL."
  value       = local.watsonx_assistant_url
}

output "watsonx_discovery_api_url" {
  description = "WatsonX Discovery URL."
  value       = local.watsonx_discovery_url
}

output "cos_instance_crn" {
  description = "COS instance CRN which is configured with the WatsonX project."
  value       = module.cos.cos_instance_crn
}

output "watsonx_assistant_integration_id" {
  description = "WatsonX assistant integration ID."
  value       = data.external.assistant_get_integration_id.result.assistant_integration_id
}

output "watsonx_discovery_project_id" {
  description = "WatsonX Discovery Project ID."
  value       = data.external.discovery_project_id.result.discovery_project_id
}
