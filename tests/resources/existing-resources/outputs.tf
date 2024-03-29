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
