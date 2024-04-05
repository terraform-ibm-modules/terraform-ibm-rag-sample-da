output "watson_assistant_instance_id" {
  value       = ibm_resource_instance.assistant_instance.id
  description = "Watson Assistant instance ID."
}

output "watson_assistant_region" {
  value       = ibm_resource_instance.assistant_instance.location
  description = "Watson Assistant instance Region."
}

output "watson_discovery_instance_id" {
  value       = ibm_resource_instance.discovery_instance.id
  description = "Watson Discovery instance ID."
}

output "watson_discovery_region" {
  value       = ibm_resource_instance.discovery_instance.location
  description = "Watson Discovery instance Region."
}

output "ci_pipeline_id" {
  value       = ibm_cd_tekton_pipeline.ci_tekton_pipeline_instance.id
  description = "Id of the CI tekton pipeline instance."
}

output "cd_pipeline_id" {
  value       = ibm_cd_tekton_pipeline.cd_tekton_pipeline_instance.id
  description = "Id of the CD tekton pipeline instance."
}
