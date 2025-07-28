
output "name" {
  value = github_repository.repo.name
}

output "admin_project_id" {
  description = "ID of the admin project created for this repository when allow_tf_workspaces is true"
  value       = var.allow_tf_workspaces ? local.admin_project_name : null
}
