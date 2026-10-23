locals {
  watson_discovery_api_version     = "2023-03-31"
  watson_discovery_url             = var.watson_discovery_url
  watson_discovery_project_name    = var.watson_discovery_project_name
  watson_discovery_collection_name = var.watson_discovery_collection_name
  watson_discovery_project_id      = shell_script.discovery_project.output.project_id
  watson_discovery_collection_id   = shell_script.discovery_collection.output.collection_id
}

# The http provider only has a data source, so it cannot create and delete objects.
# The project and collection lifecycle is handled by curl calls in scripts/discovery-utils.sh
# (the same pattern the watson-assistant module uses for the assistant itself).
# Both create functions adopt an existing object with the same name instead of creating a second one.

# Discovery project creation
resource "shell_script" "discovery_project" {
  lifecycle_commands {
    create = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      create_project
    EOT
    read   = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      read_project
    EOT
    update = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      update_project
    EOT
    delete = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      delete_project
    EOT
  }

  environment = {
    WATSON_DISCOVERY_URL          = "https:${local.watson_discovery_url}"
    WATSON_DISCOVERY_API_VERSION  = local.watson_discovery_api_version
    WATSON_DISCOVERY_PROJECT_NAME = local.watson_discovery_project_name
  }

  sensitive_environment = {
    IBMCLOUD_API_KEY = var.ibmcloud_api_key
  }

  # Change in apikey should not trigger project re-create
  lifecycle {
    ignore_changes = [sensitive_environment]
  }
}

# Discovery collection creation
resource "shell_script" "discovery_collection" {
  lifecycle_commands {
    create = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      create_collection
    EOT
    read   = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      read_collection
    EOT
    update = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      update_collection
    EOT
    delete = <<-EOT
      set -e
      source ./${path.module}/scripts/discovery-utils.sh
      delete_collection
    EOT
  }

  environment = {
    WATSON_DISCOVERY_URL             = "https:${local.watson_discovery_url}"
    WATSON_DISCOVERY_API_VERSION     = local.watson_discovery_api_version
    WATSON_DISCOVERY_PROJECT_ID      = local.watson_discovery_project_id
    WATSON_DISCOVERY_COLLECTION_NAME = local.watson_discovery_collection_name
  }

  sensitive_environment = {
    IBMCLOUD_API_KEY = var.ibmcloud_api_key
  }

  lifecycle {
    ignore_changes = [sensitive_environment]
  }
}

# Read the project back with the http provider (status and details for the output)
data "http" "discovery_project" {
  url = "https:${local.watson_discovery_url}/v2/projects/${local.watson_discovery_project_id}?version=${local.watson_discovery_api_version}"
  request_headers = {
    Authorization  = var.sensitive_tokendata
    "Content-Type" = "application/json"
  }

  retry {
    attempts     = 3
    min_delay_ms = 2000
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Reading the Discovery project failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}

# discovery file upload
resource "null_resource" "discovery_file_upload" {
  depends_on = [shell_script.discovery_collection]
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/discovery-file-upload.sh \"https:${local.watson_discovery_url}\" \"${local.watson_discovery_project_id}\" \"${local.watson_discovery_collection_id}\" \"${var.watson_discovery_collection_artifacts_path}\" "
    interpreter = ["/bin/bash", "-c"]
    quiet       = true
    environment = {
      IAM_TOKEN = var.sensitive_tokendata
    }
  }
}

# Drop the old restapi objects from state without calling their destroy.
# The create scripts adopt the existing project and collection by name.
removed {
  from = restapi_object.configure_discovery_project
  lifecycle {
    destroy = false
  }
}

removed {
  from = restapi_object.configure_discovery_collection
  lifecycle {
    destroy = false
  }
}
