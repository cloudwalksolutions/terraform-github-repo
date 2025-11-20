
######################
### State Bucket #####
######################

module "tfstate_bucket" {
  for_each = var.allow_tf_workspaces ? local.sa_emails : {}

  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 10.0"

  project_id = local.workspace_project_id
  location   = var.gcp_region

  names  = ["${github_repository.repo.name}-tfstate"]
  prefix = length(local.sa_emails) > 1 ? "${each.key}-${var.state_bucket_prefix}": var.state_bucket_prefix

  set_admin_roles = true
  versioning = {
    first = true
  }
  admins = [
    "serviceAccount:${each.key}",
  ]

  depends_on = [
    google_service_account.workspace_service_accounts,
    module.gcp_folder,
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
  for_each = var.allow_tf_workspaces ? local.sa_emails : {}

  repository    = github_repository.repo.name
  variable_name = length(local.sa_emails) > 1 ? "${upper(each.key)}_GCP_SERVICE_ACCOUNT" : "GCP_SERVICE_ACCOUNT"
  value         = each.value
}


resource "github_actions_variable" "gcp_storage_bucket" {
  for_each = var.allow_tf_workspaces ? toset(local.lifecycles) : toset([])

  repository    = github_repository.repo.name
  variable_name = length(local.lifecycles) > 1 ? "${each.key}_GCP_BUCKET_NAME" : "GCP_BUCKET_NAME"
  value         = module.tfstate_bucket[each.key].name
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

