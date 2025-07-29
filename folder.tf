
module "gcp_folder" {
  count = var.create_gcp_folder ? 1 : 0

  source = "git::https://github.com/cloudwalksolutions/terraform-google-folder.git?ref=0.0.23"

  parent_folder_id = var.gcp_parent_folder_id
  folder_name      = var.gcp_folder_name != "" ? var.gcp_folder_name : var.name
  projects_dict    = local.projects_to_create
  billing_account  = var.gcp_billing_account_id

  org_id = var.gcp_org_id

  create_service_account   = !var.allow_tf_workspaces
  sa_is_security_admin     = var.allow_tf_workspaces
  sa_is_billing_user       = var.allow_tf_workspaces
  sa_prefix                = var.gcp_sa_prefix
  sa_name                  = local.full_sa_name
  sa_project               = local.admin_project_id
  extra_folder_permissions = local.combined_sa_permissions
}


module "admin_project_iam" {
  count = var.allow_tf_workspaces && var.create_gcp_folder ? 1 : 0

  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 8.1"

  projects = [
    local.admin_project_id,
  ]

  bindings = {
    "roles/storage.admin" = [
      "serviceAccount:${local.sa_email}"
    ]
    "roles/iam.serviceAccountAdmin" = [
      "serviceAccount:${local.sa_email}"
    ]
    "roles/resourcemanager.projectIamAdmin" = [
      "serviceAccount:${local.sa_email}"
    ]
    "roles/iam.serviceAccountUser" = [
      "serviceAccount:${local.sa_email}"
    ]
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${local.sa_email}"
    ]
    "roles/iam.serviceAccountTokenCreator" = [
      "serviceAccount:${local.sa_email}"
    ]
  }

  depends_on = [module.gcp_folder]
}


module "workspace_folder_iam" {
  count = var.create_gcp_folder && var.allow_tf_workspaces ? 1 : 0

  source  = "terraform-google-modules/iam/google//modules/folders_iam"
  version = "~> 8.1"

  folders = [
    module.gcp_folder[0].folder_id,
  ]

  bindings = {
    for permission in local.workspace_folder_permissions :
    "roles/${permission}" => [
      "serviceAccount:${local.sa_email}"
    ]
  }

  depends_on = [module.gcp_folder]
}


resource "google_storage_bucket_iam_member" "tfstate_access" {
  for_each = toset(var.tfstate_buckets)

  bucket = each.key
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.sa_email}"

  depends_on = [
    google_service_account.workspace_service_account
  ]
}

