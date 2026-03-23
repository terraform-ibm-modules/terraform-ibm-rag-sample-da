
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

output "watson_studio_instance" {
  description = "Watson Studio instance details including region and CRN. Required for storage delegation entitlement."
  value = var.watsonx_project_delegated ? {
    id      = ibm_resource_instance.watson_studio[0].id
    crn     = ibm_resource_instance.watson_studio[0].crn
    name    = ibm_resource_instance.watson_studio[0].name
    region  = ibm_resource_instance.watson_studio[0].location
    status  = ibm_resource_instance.watson_studio[0].status
    message = "Watson Studio instance created successfully in ${ibm_resource_instance.watson_studio[0].location} region to provide storage delegation entitlement"
  } : null
}
