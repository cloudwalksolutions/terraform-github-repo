
locals {
  template = var.template_repo != "" ? toset([var.template_repo]) : toset([])

  all_branches = concat(var.new_branches, [var.source_branch])

  name_items = split("-", var.name)
  name_prefix = length(local.name_items) > 0 ? local.name_items[0] : var.name

  admin_project_label = "${var.state_bucket_prefix}-admin"
  admin_project_id    = "${local.name_prefix}-${local.admin_project_label}-project"

  admin_project_apis = [
    "storage.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]

  projects_to_create = var.allow_tf_workspaces ? merge(
    var.gcp_projects_to_create,
    {
      (local.admin_project_label) = local.admin_project_apis
    }
  ) : var.gcp_projects_to_create

  workload_identity_pool_id           = var.wi_pool_id != "" ? var.wi_pool_id : "github-actions-pool"
  gcp_workload_identity_prefix        = var.allow_tf_workspaces ? "projects/${data.google_project.project[0].number}/locations/global/workloadIdentityPools/${local.workload_identity_pool_id}" : ""
  gcp_workload_identity_iam_principal = "${local.gcp_workload_identity_prefix}/attribute.repository/${var.org_name}/${github_repository.repo.name}"
  gcp_workload_identity_provider      = "${local.gcp_workload_identity_prefix}/providers/github-provider"

  state_bucket_name = "${var.state_bucket_prefix}-${github_repository.repo.name}-tfstate"

  sa_name      = "${var.name}-ws"
  full_sa_name = var.gcp_sa_prefix != "" ? "${var.gcp_sa_prefix}-${local.sa_name}" : local.sa_name

  sa_email = "${local.full_sa_name}@${local.admin_project_id}.iam.gserviceaccount.com"
}


