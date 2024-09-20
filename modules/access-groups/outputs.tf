output "access_group_id" {
  value = var.existing_access_group_name != null ? module.access_group[0].id : null
  description = "Access group ID."
}

output "access_group_policy_ids" {
  value = var.existing_access_group_name != null ? module.access_group[0].policy_ids : null
  description = "List of access group policy IDs."
}
