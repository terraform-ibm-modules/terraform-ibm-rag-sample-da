output "watson_discovery_api_url" {
  description = "Watson Discovery URL."
  value       = "https:${local.watson_discovery_url}"
}

output "watson_discovery_project_id" {
  description = "Watson Discovery Project ID."
  value       = local.watson_discovery_project_id
}

output "watson_discovery_collection_id" {
  description = "Watson Discovery Collection ID."
  value       = local.watson_discovery_collection_id
}

output "watson_discovery_project" {
  description = "Watson Discovery Project details."
  value       = jsondecode(data.http.discovery_project.response_body)
}
