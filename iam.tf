
data "google_project" "project" {
  count = var.allow_tf_workspaces ? 1 : 0

  project_id = local.workspace_project_id

  depends_on = [
    module.gcp_folder,
  ]
}


resource "google_iam_workload_identity_pool" "github_pool" {
  count = var.allow_tf_workspaces && var.create_workload_identity_pool ? 1 : 0

  project                   = local.workspace_project_id
  workload_identity_pool_id = local.workload_identity_pool_id
  display_name              = "GH WI Pool - ${github_repository.repo.name}"
  description               = "GitHub Workload Identity Pool - ${github_repository.repo.name}"
  disabled                  = false

  depends_on = [
    module.gcp_folder,
  ]
}


resource "google_iam_workload_identity_pool_provider" "github_provider" {
  count = var.allow_tf_workspaces && var.create_workload_identity_pool_provider ? 1 : 0

  project                            = local.workspace_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"
  description                        = "OIDC provider for GitHub Actions"
  disabled                           = false

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  attribute_condition = "assertion.repository_owner == '${var.org_name}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  depends_on = [
    google_iam_workload_identity_pool.github_pool,
  ]
}


resource "google_service_account" "workspace_service_accounts" {
  for_each = var.allow_tf_workspaces ? toset(local.workspace_sa_lifecycles) : toset([])

  project      = local.workspace_project_id
  account_id   = length(local.workspace_sa_lifecycles) > 1 ? "${each.key}-${local.sa_name}" : local.sa_name
  display_name = "Terraform-managed service account"
  description  = "${each.key} folder admin service account"
}


resource "google_service_account_iam_binding" "workload_identity_binding" {
  for_each = var.allow_tf_workspaces ? toset(local.lifecycles) : toset([])

  service_account_id = length(local.lifecycles) > 1 ? "projects/${local.workspace_project_id}/serviceAccounts/${each.key}-${local.sa_email}" : "projects/${local.workspace_project_id}/serviceAccounts/${local.sa_email}"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${local.gcp_workload_identity_iam_principal}",
  ]

  depends_on = [
    google_service_account.workspace_service_accounts,
    google_iam_workload_identity_pool_provider.github_provider,
  ]
}


