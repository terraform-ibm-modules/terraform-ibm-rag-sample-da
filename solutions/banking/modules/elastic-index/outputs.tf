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
