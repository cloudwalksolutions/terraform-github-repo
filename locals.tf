
locals {
  template = var.template_repo != "" ? toset([var.template_repo]) : toset([])

  all_branches = concat(var.new_branches, [var.source_branch])

  gcp_workload_identity_prefix        = var.allow_tf_workspaces && var.gcp_project_id != "" ? "projects/${data.google_project.project[0].number}/locations/global/workloadIdentityPools/${var.wi_pool_id}" : ""
  gcp_workload_identity_iam_principal = "${local.gcp_workload_identity_prefix}/attribute.repository/${var.org_name}/${github_repository.repo.name}"
  gcp_workload_identity_provider      = "${local.gcp_workload_identity_prefix}/providers/github-provider"

  state_bucket_name = "${var.state_bucket_prefix}-${github_repository.repo.name}-tfstate"

  gcp_service_account_permissions = length(var.gcp_service_account_permissions) > 0 ? var.gcp_service_account_permissions : [
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountUser",
  ]
}


