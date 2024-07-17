locals {
  credentials_data = jsondecode(data.ibm_resource_key.elastic_credentials.credentials_json).connection.https
  elastic_auth_base64 = sensitive(base64encode("${local.credentials_data.authentication.username}:${local.credentials_data.authentication.password}"))
  # Compose the URL without credentials to keep the latter sensitive
  elastic_url = "${local.credentials_data.scheme}://${local.credentials_data.hosts[0].hostname}:${local.credentials_data.hosts[0].port}"
  elastic_ca_cert = local.credentials_data.certificate.certificate_base64
  elastic_instance_id = split(":", var.elastic_instance_crn)[7]
}

data "ibm_resource_key" "elastic_credentials" {
  resource_instance_id = var.elastic_instance_crn
  name = var.elastic_credentials_name
}

# Elastic index creation
# Note: Elastic uses CA certificate for connection, and restapi does not have an option to specify that
# Therefore the Elastic APIs are used from shell_script
resource "shell_script" "elastic_index" {
  lifecycle_commands {
    create = file("${path.module}/scripts/elastic-index-create.sh")
    delete = file("${path.module}/scripts/elastic-index-destroy.sh")
    read   = file("${path.module}/scripts/elastic-index-read.sh")
  }

  environment = {
    ELASTIC_URL         = local.elastic_url
    ELASTIC_CACERT      = local.elastic_ca_cert
    ELASTIC_INSTANCE_ID = local.elastic_instance_id
    ELASTIC_INDEX_NAME  = urlencode(var.elastic_index_name)
    MODULE_PATH         = path.module
  }

  sensitive_environment = {
    ELASTIC_AUTH_BASE64 = local.elastic_auth_base64
  }
  
  # Change in apikey should not trigger assistant re-create
  lifecycle {
    ignore_changes = [ sensitive_environment ]
  }
}
/*
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
*/