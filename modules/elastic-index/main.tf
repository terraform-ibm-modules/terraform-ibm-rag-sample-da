locals {
  elastic_auth_base64 = sensitive(base64encode("${var.elastic_service_binding.username}:${var.elastic_service_binding.password}"))
}

# Elastic index creation

resource "elasticstack_elasticsearch_index" "sample_index" {
  name                = var.elastic_index_name
  deletion_protection = false
  mappings = jsonencode({ properties = {
    for key, value in jsondecode(var.elastic_index_mapping) : value => { fields = { keyword = { ignore_above = 256, type = "keyword" } }, type = "text" }
  } })
}

## Upload sample data entries

/*
# Note: Elastic uses CA certificate for connection, and restapi does not have an option to specify that
# Therefore the Elastic APIs are used from shell_script
*/

resource "shell_script" "elastic_index_entries" {
  count      = var.elastic_index_entries_file != null ? 1 : 0
  depends_on = [elasticstack_elasticsearch_index.sample_index]
  lifecycle_commands {
    create = <<-EOT
      set -e
      source ./${path.module}/scripts/elastic-index-utils.sh
      create_index_entries
    EOT
    delete = <<-EOT
      set -e
      source ./${path.module}/scripts/elastic-index-utils.sh
      delete_index_entries
    EOT
  }

  environment = {
    ELASTIC_URL          = var.elastic_service_binding.url
    ELASTIC_CACERT       = var.elastic_service_binding.ca_data_base64
    ELASTIC_INDEX_NAME   = urlencode(elasticstack_elasticsearch_index.sample_index.name)
    ELASTIC_INDEX_ID     = elasticstack_elasticsearch_index.sample_index.id # Add dependency to force upload on index recreate
    ELASTIC_ENTRIES_FILE = var.elastic_index_entries_file
    MODULE_PATH          = path.module
  }

  sensitive_environment = {
    ELASTIC_AUTH_BASE64 = local.elastic_auth_base64
  }

  # Change in apikey should not trigger assistant re-create
  lifecycle {
    ignore_changes = [sensitive_environment]
  }
}
