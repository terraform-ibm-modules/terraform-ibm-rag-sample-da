output "elastic_connection_url" {
  description = "Elastic DB connection URL."
  value       = "local.elastic_connection_url"
}

output "elastic_connection_username" {
  description = "Elastic DB connection user name."
  value       = sensitive(local.credentials_data.authentication.username)
}

output "elastic_connection_password" {
  description = "Elastic DB connection password."
  value       = sensitive(local.credentials_data.authentication.password)
}

output "elastic_connection_binding" {
  description = "Elastic DB connection attributes."
  value       = sensitive({
    url      : local.elastic_url
    username : local.credentials_data.authentication.username
    password : local.credentials_data.authentication.password
    index    : var.elastic_index_name
  })
}

output "elastic_upload_count" {
  description = "Count of uploaded entries."
  value       = var.elastic_index_entries_file != null ? tonumber(shell_script.elastic_index_entries[0].output.count) : 0
}
