output "project_id" {
  description = "ID of the created project."
  value       = module.configure_project.project_id
}

output "project_url" {
  description = "Project ID URL."
  value       = "https://dataplatform.cloud.ibm.com/projects/${module.configure_project.project_id}"
}

output "watsonx_assistant_url" {
  description = "WastonX Assistant URL."
  value       = local.watsonx_assistant_url
}

output "watsonx_discovery_url" {
  description = "WastonX Discovery URL."
  value       = local.watsonx_discovery_url
}

output "cos_instance_guid" {
  description = "COS instance GUID."
  value       = module.cos.cos_instance_guid
}

output "cos_instance_crn" {
  description = "COS instance CRN."
  value       = module.cos.cos_instance_crn
}

output "cos_instance_id" {
  description = "COS instance ID."
  value       = module.cos.cos_instance_id
}

output "assistant_integration_id" {
  description = "WatsonX assistant integration ID."
  value       = data.external.assistant_get_integration_id.result.assistant_integration_id
}

output "discovery_project_id" {
  description = "WatsonX Discovery Project ID."
  value       = data.external.discovery_project_id.result.discovery_project_id
}
