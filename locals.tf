
locals {
  template = var.template_repo != "" ? toset([var.template_repo]) : toset([])

  all_branches = concat(var.new_branches, [var.source_branch])

  gcp_workload_identity_prefix        = var.allow_tf_workspaces && var.gcp_project_id != "" ? "projects/${data.google_project.project[0].number}/locations/global/workloadIdentityPools/${var.wi_pool_id}" : ""
  gcp_workload_identity_iam_principal = "${local.gcp_workload_identity_prefix}/attribute.repository/${var.org_name}/${github_repository.repo.name}"
  gcp_workload_identity_provider      = "${local.gcp_workload_identity_prefix}/providers/github-provider"

  state_bucket_name = "${var.state_bucket_prefix}-${github_repository.repo.name}-tfstate"

  sa_name      = "${var.name}-ws"
  full_sa_name = var.gcp_sa_prefix != "" ? "${var.gcp_sa_prefix}-${local.sa_name}" : local.sa_name

  sa_email = "${local.full_sa_name}@${var.gcp_project_id}.iam.gserviceaccount.com"
}


