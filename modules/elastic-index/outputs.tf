output "elastic_index" {
  description = "Elastic DB index attributes."
  value       = elasticstack_elasticsearch_index.sample_index
}

output "elastic_upload_count" {
  description = "Count of uploaded entries."
  value       = var.elastic_index_entries_file != null ? tonumber(shell_script.elastic_index_entries[0].output.count) : 0
}
