output "watsonx_project_id" {
  description = "ID of the created watsonx project."
  value       = local.use_watsonx_machine_learning ? module.configure_wml_project[0].watsonx_project_id : null
}

output "watsonx_project_url" {
  description = "watsonx project ID URL."
  value       = local.use_watsonx_machine_learning ? "${local.watsonx_project_base_url}/projects/${module.configure_wml_project[0].watsonx_project_id}" : null
}

output "watsonx_orchestrate_api_url" {
  description = "watsonx Orchestrate API URL. See [API reference](https://cloud.ibm.com/docs/apis/assistant-v2)."
  value       = var.watsonx_orchestrate_instance_crn != null ? "https://api.${local.watsonx_orchestrate_instance_region}.assistant.watson.cloud.ibm.com/instances/${local.watsonx_orchestrate_instance_guid}" : null
}

output "watsonx_orchestrate_id" {
  description = "Instance ID (GUID) of the watsonx Orchestrate service instance."
  value       = local.watsonx_orchestrate_instance_guid
}

output "watsonx_orchestrate_region" {
  description = "Region of the watsonx Orchestrate service instance."
  value       = local.watsonx_orchestrate_instance_region
}

output "watsonx_orchestrate_crn" {
  description = "Cloud Resource Name (CRN) of the watsonx Orchestrate service instance."
  value       = var.watsonx_orchestrate_instance_crn
}

output "watsonx_orchestrate_integration_id" {
  description = "ID of the watsonx Orchestrate web chat integration (agent environment ID)."
  value       = var.watsonx_orchestrate_integration_id
}

output "watson_discovery_api_url" {
  description = "Watson Discovery URL."
  value       = local.use_watson_discovery ? "https:${local.watson_discovery_url}" : null
}

output "cos_instance_crn" {
  description = "Cloud Resource Name (CRN) of the Object Storage instance which is configured with the watsonx project."
  value       = local.use_watsonx_machine_learning ? module.configure_wml_project[0].watson_ml_cos_instance.cos_instance_crn : null
}

output "watson_discovery_project_id" {
  description = "Watson Discovery Project ID."
  value       = local.use_watson_discovery ? module.configure_discovery_project[0].watson_discovery_project_id : null
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
