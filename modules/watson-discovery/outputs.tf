output "watson_discovery_api_url" {
  description = "Watson Discovery URL."
  value       = "https:${local.watson_discovery_url}"
}

output "watson_discovery_project_id" {
  description = "Watson Discovery Project ID."
  value       = restapi_object.configure_discovery_project.id
}
