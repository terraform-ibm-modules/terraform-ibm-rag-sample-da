
output "watsonx_project_id" {
  value       = local.watsonx_project_id
  description = "The ID watsonx project that's created."
}

output "watsonx_project_location" {
  value       = resource.restapi_object.configure_project.id
  description = "The location watsonx project that's created."
}

output "watson_ml_cos_instance" {
  description = "COS instance for Watson Machine Learning project."
  value       = module.cos
}
