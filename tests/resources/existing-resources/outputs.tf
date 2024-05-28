output "watson_assistant_instance_id" {
  value       = ibm_resource_instance.assistant_instance.guid
  description = "Watson Assistant instance ID."
}

output "watson_assistant_region" {
  value       = ibm_resource_instance.assistant_instance.location
  description = "Watson Assistant instance Region."
}

output "watson_discovery_instance_id" {
  value       = ibm_resource_instance.discovery_instance.guid
  description = "Watson Discovery instance ID."
}

output "watson_discovery_region" {
  value       = ibm_resource_instance.discovery_instance.location
  description = "Watson Discovery instance Region."
}

output "watson_machine_learning_instance_crn" {
  value       = ibm_resource_instance.machine_learning_instance.crn
  description = "Watson Machine Learning instance CRN."
}

output "watson_machine_learning_instance_guid" {
  value       = ibm_resource_instance.machine_learning_instance.guid
  description = "Watson Machine Learning instance GUID."
}

output "watson_machine_learning_instance_resource_name" {
  value       = ibm_resource_instance.machine_learning_instance.resource_name
  description = "Watson Machine Learning instance resource name."
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

output "signing_key" {
  value       = local.signing_key_payload
  sensitive   = true
  description = "Signing key payload."
}
