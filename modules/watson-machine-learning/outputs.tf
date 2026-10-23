
output "watsonx_project_id" {
  value       = local.watsonx_project_id
  description = "The ID watsonx project that's created."
}

output "watsonx_project_bucket_name" {
  value       = try(local.watsonx_project_data.entity.storage.properties.bucket_name, null)
  description = "The name of the COS bucket created by the watsonx.ai project."
}

output "watsonx_project_url" {
  value       = "${local.dataplatform_ui}/projects/${local.watsonx_project_id}?context=wx&sync_account_id=${module.crn_parser.account_id}"
  description = "The URL of the watsonx.ai project that is created."
}

output "watson_ml_cos_instance" {
  description = "COS instance for Watson Machine Learning project."
  value       = module.cos
}
