
locals {
  template = var.template_repo != "" ? toset([var.template_repo]) : toset([])

  all_branches = concat(var.new_branches, [var.source_branch])

  name_items = split("-", var.name)

  name_prefix = length(local.name_items) > 1 ? join("-", slice(local.name_items, 0, length(local.name_items) - 1)) : var.name

  admin_project_prefix = var.admin_project_prefix != "" ? var.admin_project_prefix : var.state_bucket_prefix
  admin_project_label = "${local.admin_project_prefix}-admin"
  admin_project_id    = "${local.name_prefix}-${local.admin_project_label}-project"

  workspace_project_id = var.workspace_project_id != "" ? var.workspace_project_id : local.admin_project_id

  admin_project_apis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
  ]

  projects_to_create = var.allow_tf_workspaces ? merge(
    var.gcp_projects_to_create,
    {
      (local.admin_project_label) = local.admin_project_apis
    }
  ) : var.gcp_projects_to_create

  workload_identity_pool_id           = "github-actions-pool"
  gcp_workload_identity_prefix        = var.allow_tf_workspaces ? "projects/${data.google_project.project[0].number}/locations/global/workloadIdentityPools/${local.workload_identity_pool_id}" : ""
  gcp_workload_identity_iam_principal = "${local.gcp_workload_identity_prefix}/attribute.repository/${var.org_name}/${github_repository.repo.name}"
  gcp_workload_identity_provider      = "${local.gcp_workload_identity_prefix}/providers/github-provider"

  state_bucket_name = "${var.state_bucket_prefix}-${github_repository.repo.name}-tfstate"

  sa_name      = "${var.name}-ws"
  full_sa_name = var.gcp_sa_prefix != "" ? "${var.gcp_sa_prefix}-${local.sa_name}" : local.sa_name

  sa_email = "${local.full_sa_name}@${local.workspace_project_id}.iam.gserviceaccount.com"

  workspace_folder_permissions = var.allow_tf_workspaces ? [
    "resourcemanager.folderAdmin",
    "resourcemanager.folderCreator",
    "resourcemanager.projectCreator",
    "resourcemanager.projectDeleter",
    "resourcemanager.projectIamAdmin",
    "iam.securityAdmin",
    "iam.serviceAccountAdmin",
    "iam.serviceAccountUser",
    "serviceusage.serviceUsageAdmin"
  ] : []

  combined_sa_permissions = concat(var.gcp_service_account_permissions, local.workspace_folder_permissions)
}


