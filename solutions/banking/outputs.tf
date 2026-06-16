output "watsonx_project_id" {
  description = "ID of the created watsonx project."
  value       = local.use_watsonx_machine_learning ? module.configure_wml_project[0].watsonx_project_id : null
}

output "watsonx_project_url" {
  description = "watsonx project ID URL."
  value       = local.use_watsonx_machine_learning ? "${local.watsonx_project_base_url}/projects/${module.configure_wml_project[0].watsonx_project_id}" : null
}

output "watsonx_assistant_api_url" {
  description = "watsonx Assistant URL."
  value       = "https:${local.watsonx_assistant_url}"
}

output "watson_discovery_api_url" {
  description = "watsonx Discovery URL."
  value       = local.use_watsonx_discovery ? "https:${local.watsonx_discovery_url}" : null
}

output "cos_instance_crn" {
  description = "Cloud Resource Name (CRN) of the Object Storage instance which is configured with the watsonx project."
  value       = local.use_watsonx_machine_learning ? module.configure_wml_project[0].watson_ml_cos_instance.cos_instance_crn : null
}

output "watsonx_assistant_integration_id" {
  description = "watsonx Assistant integration ID."
  value       = module.configure_watson_assistant.watsonx_assistant_integration_id
}

output "watsonx_assistant_environment" {
  description = "watsonx Assistant target environment."
  value       = module.configure_watson_assistant.watsonx_assistant_environment
}

output "watson_discovery_project_id" {
  description = "watsonx Discovery Project ID."
  value       = local.use_watsonx_discovery ? module.configure_discovery_project[0].watson_discovery_project_id : null
}

output "watsonx_assistant_skills_status" {
  description = "watsonx Assistant skills status"
  value       = module.configure_watson_assistant.watsonx_assistant_skills_status
}

output "elastic_collection_count" {
  description = "Count of sample data items uploaded to elastic index"
  value       = local.use_elastic_index ? module.configure_elastic_index[0].elastic_upload_count : 0
}

output "cluster_workload_ingress_subdomain" {
  description = "Subdomain of the cluster's public ingress"
  value       = var.cluster_name != null && var.provision_public_ingress ? module.cluster_ingress[0].cluster_workload_ingress_subdomain : null
}

output "sample_app_public_url" {
  description = "URL of the public route of the sample app deployed on ROKS cluster"
  value       = var.cluster_name != null && var.provision_public_ingress ? "https://gen-ai-rag-sample-app-tls-dev.${module.cluster_ingress[0].cluster_workload_ingress_subdomain}" : null
}
