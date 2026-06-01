output "watson_assistant_instance_crn" {
  value       = ibm_resource_instance.assistant_instance.crn
  description = "CRN of the watsonx Assistant instance"
}

output "watson_discovery_instance_crn" {
  value       = ibm_resource_instance.discovery_instance.crn
  description = "CRN of the Watson Discovery instance"
}

output "watson_machine_learning_instance_crn" {
  value       = ibm_resource_instance.machine_learning_instance.crn
  description = "Watson Machine Learning instance CRN."
}

output "watson_studio_instance_crn" {
  value       = ibm_resource_instance.studio_instance.crn
  description = "Watson Studio instance CRN."
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
