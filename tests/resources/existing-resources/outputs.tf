output "watsonx_assistant_instance_crn" {
  value       = ibm_resource_instance.assistant_instance.crn
  description = "CRN of the watsonx Assistant instance"
}

output "watsonx_assistant_instance_id" {
  value       = ibm_resource_instance.assistant_instance.guid
  description = "GUID of the watsonx Assistant instance"
}

output "watsonx_assistant_region" {
  value       = ibm_resource_instance.assistant_instance.location
  description = "Region of the watsonx Assistant instance"
}

output "watsonx_discovery_instance_crn" {
  value       = ibm_resource_instance.discovery_instance.crn
  description = "CRN of the watsonx Discovery instance"
}

output "watsonx_discovery_instance_id" {
  value       = ibm_resource_instance.discovery_instance.guid
  description = "GUID of the watsonx Discovery instance"
}

output "watsonx_discovery_region" {
  value       = ibm_resource_instance.discovery_instance.location
  description = "Region of the watsonx Discovery instance"
}

output "watsonx_machine_learning_instance_crn" {
  value       = ibm_resource_instance.machine_learning_instance.crn
  description = "CRN of the watsonx Machine Learning instance"
}

output "watsonx_machine_learning_instance_resource_name" {
  value       = ibm_resource_instance.machine_learning_instance.resource_name
  description = "watsonx Machine Learning instance resource name."
}

output "watsonx_studio_instance_crn" {
  value       = ibm_resource_instance.studio_instance.crn
  description = "CRN of the watsonx Studio instance."
}

output "ci_pipeline_id" {
  value       = ibm_cd_tekton_pipeline.ci_tekton_pipeline_instance.id
  description = "Id of the CI tekton pipeline instance."
}

output "cd_pipeline_id" {
  value       = ibm_cd_tekton_pipeline.cd_tekton_pipeline_instance.id
  description = "Id of the CD tekton pipeline instance."
}

output "resource_group_name" {
  value       = module.resource_group.resource_group_name
  description = "Resource group name."
}

output "cluster_name" {
  value       = var.create_ocp_cluster ? module.ocp_base[0].cluster_name : null
  description = "The name of the provisioned cluster."
}

output "elasticsearch_crn" {
  value       = module.elasticsearch.crn
  description = "Elasticsearch instance CRN."
  depends_on  = [time_sleep.wait_for_elasticsearch_ready]
}

output "kms_instance_crn" {
  value       = module.key_protect.key_protect_crn
  description = "CRN of created KMS instance"
}

output "region" {
  value       = var.region
  description = "Region"
}

output "secrets_manager_instance_crn" {
  value       = module.secrets_manager.secrets_manager_crn
  description = "CRN of the Secrets Manager instance"
}

output "secrets_manager_guid" {
  value       = module.secrets_manager.secrets_manager_guid
  description = "GUID of Secrets Manager instance"
}

output "secrets_manager_region" {
  value       = module.secrets_manager.secrets_manager_region
  description = "Region of the Secrets Manager instance"
}
