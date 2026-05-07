
output "watsonx_project_id" {
  value       = module.configure_project.watsonx_ai_project_id
  description = "The ID watsonx project that's created."
}

output "watson_ml_cos_instance" {
  description = "COS instance for Watson Machine Learning project."
  value       = module.cos
}
