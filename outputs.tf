
output "name" {
  value = github_repository.repo.name
}

output "admin_project_id" {
  description = "ID of the admin project created for this repository when allow_tf_workspaces is true"
  value       = var.allow_tf_workspaces ? local.workspace_project_id : null
}

output "workspace_service_accounts" {
  description = "The service account each lifecycle's workspace runs as, keyed by lifecycle"
  value       = var.allow_tf_workspaces ? local.sa_emails : {}
}
