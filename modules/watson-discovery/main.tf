locals {
  watson_discovery_url             = var.watson_discovery_url
  watson_discovery_project_name    = var.watson_discovery_project_name
  watson_discovery_collection_name = var.watson_discovery_collection_name
}

# Discovery project creation
resource "restapi_object" "configure_discovery_project" {
  path           = local.watson_discovery_url
  read_path      = "${local.watson_discovery_url}/v2/projects/{id}?version=2023-03-31"
  read_method    = "GET"
  create_path    = "${local.watson_discovery_url}/v2/projects?version=2023-03-31"
  create_method  = "POST"
  id_attribute   = "project_id"
  destroy_method = "DELETE"
  destroy_path   = "${local.watson_discovery_url}/v2/projects/{id}?version=2023-03-31"
  data           = <<-EOT
                  {
                    "name": "${local.watson_discovery_project_name}",
                    "type": "document_retrieval"
                  }
                  EOT
  update_method  = "POST"
  update_path    = "${local.watson_discovery_url}/v2/projects/{id}?version=2023-03-31"
  update_data    = <<-EOT
                  {
                    "name": "${local.watson_discovery_project_name}",
                    "type": "document_retrieval"
                  }
                  EOT
}

# Discovery collection creation
resource "restapi_object" "configure_discovery_collection" {
  depends_on     = [restapi_object.configure_discovery_project]
  path           = local.watson_discovery_url
  read_path      = "${local.watson_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections/{id}?version=2023-03-31"
  read_method    = "GET"
  create_path    = "${local.watson_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections?version=2023-03-31"
  create_method  = "POST"
  id_attribute   = "collection_id"
  destroy_method = "DELETE"
  destroy_path   = "${local.watson_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections/{id}?version=2023-03-31"
  data           = <<-EOT
                  {
                    "name": "${local.watson_discovery_collection_name}",
                    "description": "Sample data"
                  }
                  EOT
  update_method  = "POST"
  update_path    = "${local.watson_discovery_url}/v2/projects/${restapi_object.configure_discovery_project.id}/collections/{id}?version=2023-03-31"
  update_data    = <<-EOT
                  {
                    "name": "${local.watson_discovery_collection_name}",
                    "description": "Sample data"
                  }
                  EOT
}

# discovery file upload
resource "null_resource" "discovery_file_upload" {
  depends_on = [restapi_object.configure_discovery_collection]
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/discovery-file-upload.sh \"https:${local.watson_discovery_url}\" \"${restapi_object.configure_discovery_project.id}\" \"${restapi_object.configure_discovery_collection.id}\" \"${var.watson_discovery_collection_artifacts_path}\" "
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
    environment = {
      IAM_TOKEN = var.sensitive_tokendata
    }
  }
}
