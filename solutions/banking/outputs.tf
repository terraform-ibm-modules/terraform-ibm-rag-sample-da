output "watsonx_project_id" {
  description = "ID of the created WatsonX project."
  value       = local.use_watson_machine_learning ? module.configure_wml_project[0].watsonx_project_id : null
}

output "watsonx_project_url" {
  description = "WatsonX project ID URL."
  value       = local.use_watson_machine_learning ? "https://dataplatform.cloud.ibm.com/projects/${module.configure_wml_project[0].watsonx_project_id}" : null
}

output "watsonx_assistant_api_url" {
  description = "WatsonX Assistant URL."
  value       = local.watsonx_assistant_url
}

output "watson_discovery_api_url" {
  description = "Watson Discovery URL."
  value       = local.use_watson_discovery ? "https:${local.watson_discovery_url}" : null
}

output "cos_instance_crn" {
  description = "COS instance CRN which is configured with the WatsonX project."
  value       = local.use_watson_machine_learning ? module.configure_wml_project[0].watson_ml_cos_instance.cos_instance_crn : null
}

output "watsonx_assistant_integration_id" {
  description = "WatsonX assistant integration ID."
  value       = shell_script.watson_assistant.output["assistant_integration_id"]
}

output "watson_discovery_project_id" {
  description = "Watson Discovery Project ID."
  value       = local.use_watson_discovery ? module.configure_discovery_project[0].watson_discovery_project_id : null
}
