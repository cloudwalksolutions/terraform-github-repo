
######################
### State Bucket #####
######################

module "tfstate_bucket" {
  count = var.allow_tf_workspaces ? 1 : 0

  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 10.0"

  project_id = local.workspace_project_id
  location   = var.gcp_region

  names  = ["${github_repository.repo.name}-tfstate"]
  prefix = var.state_bucket_prefix

  set_admin_roles = true
  versioning = {
    first = true
  }
  admins = [
    "serviceAccount:${local.sa_email}",
  ]

  depends_on = [
    google_service_account.workspace_service_account,
    module.gcp_folder,
  ]
}


module "state_bucket" {
  count = var.allow_tf_workspaces ? 1 : 0

  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 10.0"

  project_id = var.gcp_project_id
  location   = var.gcp_region

  names  = ["${github_repository.repo.name}-tfstate"]
  prefix = var.state_bucket_prefix_legacy

  set_admin_roles = true
  versioning = {
    first = true
  }
  admins = [
    "serviceAccount:${local.sa_email}",
  ]

  depends_on = [
    google_service_account.workspace_service_account,
    module.gcp_folder,
  ]
}


############################
### Workload Identity ######
############################

data "google_project" "project" {
  count = var.allow_tf_workspaces ? 1 : 0

  project_id = local.workspace_project_id

  depends_on = [
    module.gcp_folder,
  ]
}

resource "google_service_account" "workspace_service_account" {
  count = !var.create_gcp_folder && var.allow_tf_workspaces ? 1 : 0

  project      = local.workspace_project_id
  account_id   = local.sa_name
  display_name = "Workspace admin for ${github_repository.repo.name}"
}


resource "google_iam_workload_identity_pool" "github_pool" {
  count = var.allow_tf_workspaces && var.create_workload_identity_pool ? 1 : 0

  project                   = local.workspace_project_id
  workload_identity_pool_id = local.workload_identity_pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"
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


resource "google_service_account_iam_binding" "workload_identity_binding" {
  count = var.allow_tf_workspaces ? 1 : 0

  service_account_id = "projects/${local.workspace_project_id}/serviceAccounts/${local.sa_email}"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${local.gcp_workload_identity_iam_principal}",
  ]

  depends_on = [
    google_service_account.workspace_service_account,
    google_iam_workload_identity_pool_provider.github_provider,
  ]
}


#################
### Variables ###
#################

resource "github_actions_variable" "gcp_workload_identity_pool" {
  count = var.allow_tf_workspaces ? 1 : 0

  repository    = github_repository.repo.name
  variable_name = "GCP_WORKLOAD_IDENTITY_POOL"
  value         = local.gcp_workload_identity_provider
}


resource "github_actions_variable" "gcp_project_id" {
  count = var.allow_tf_workspaces ? 1 : 0

  repository    = github_repository.repo.name
  variable_name = "GCP_PROJECT_ID"
  value         = local.workspace_project_id
}


resource "github_actions_variable" "gcp_project_number" {
  count = var.allow_tf_workspaces ? 1 : 0

  repository    = github_repository.repo.name
  variable_name = "GCP_PROJECT_NUMBER"
  value         = data.google_project.project[0].number
}


resource "github_actions_variable" "gcp_folder_id" {
  count = var.allow_tf_workspaces && var.create_gcp_folder ? 1 : 0

  repository    = github_repository.repo.name
  variable_name = "GCP_FOLDER_ID"
  value         = module.gcp_folder[0].folder_id
}


resource "github_actions_variable" "gcp_service_account" {
  count = var.allow_tf_workspaces ? 1 : 0

  repository    = github_repository.repo.name
  variable_name = "GCP_SERVICE_ACCOUNT"
  value         = local.sa_email
}


################
### Secrets ####
################

resource "github_actions_secret" "github_app_id" {
  count = var.is_github_admin && var.github_app_id != "" ? 1 : 0

  repository      = github_repository.repo.name
  secret_name     = "TF_ADMIN_APP_ID"
  plaintext_value = var.github_app_id
}


resource "github_actions_secret" "github_app_installation_id" {
  count = var.is_github_admin && var.github_app_installation_id != "" ? 1 : 0

  repository      = github_repository.repo.name
  secret_name     = "TF_ADMIN_APP_INSTALLATION_ID"
  plaintext_value = var.github_app_installation_id
}


resource "github_actions_secret" "github_app_private_key" {
  count = var.is_github_admin && var.github_app_private_key != "" ? 1 : 0

  repository      = github_repository.repo.name
  secret_name     = "TF_ADMIN_APP_PRIVATE_KEY_PEM"
  plaintext_value = var.github_app_private_key
}

