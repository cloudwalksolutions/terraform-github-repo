
module "gcp_folder" {
  count = var.create_gcp_folder ? 1 : 0

  source = "git::https://github.com/cloudwalksolutions/terraform-google-folder.git?ref=0.0.25"

  parent_folder_id = var.gcp_parent_folder_id
  folder_name      = var.gcp_folder_name != "" ? var.gcp_folder_name : var.name
  projects_dict    = local.gcp_projects_to_create
  billing_account  = var.gcp_billing_account_id

  org_id = var.gcp_org_id

  create_service_account   = true
  sa_is_security_admin     = var.allow_tf_workspaces
  sa_is_billing_user       = var.allow_tf_workspaces
  sa_name                  = length(local.lifecycles) > 1 ? "prod-${local.full_sa_name}" : local.full_sa_name
  sa_project               = local.workspace_project_id
  extra_folder_permissions = local.combined_sa_permissions
}


module "admin_project_iam" {
  for_each = var.allow_tf_workspaces && var.create_gcp_folder ? local.sa_emails : {}

  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 8.1"

  projects = [
    local.admin_project_id,
  ]

  bindings = {
    "roles/storage.admin" = [
      "serviceAccount:${each.value}"
    ]
    "roles/iam.serviceAccountAdmin" = [
      "serviceAccount:${each.value}"
    ]
    "roles/resourcemanager.projectIamAdmin" = [
      "serviceAccount:${each.value}"
    ]
    "roles/iam.serviceAccountUser" = [
      "serviceAccount:${each.value}"
    ]
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${each.value}"
    ]
    "roles/iam.serviceAccountTokenCreator" = [
      "serviceAccount:${each.value}"
    ]
  }

  depends_on = [
    module.gcp_folder,
  ]
}


module "workspace_folder_iam" {
  for_each = var.create_gcp_folder && var.allow_tf_workspaces ? local.sa_emails : {}

  source  = "terraform-google-modules/iam/google//modules/folders_iam"
  version = "~> 8.1"

  folders = [
    module.gcp_folder[0].folder_id,
  ]

  bindings = {
    for permission in local.workspace_folder_permissions :
    "roles/${permission}" => [
      "serviceAccount:${each.value}"
    ]
  }

  depends_on = [
    module.gcp_folder,
    google_service_account.workspace_service_accounts,
  ]
}


resource "google_storage_bucket_iam_member" "tfstate_access" {
  for_each = length(local.sa_emails) == 1 ? toset(var.tfstate_buckets) : toset([])

  bucket = each.key
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.sa_email}"

  depends_on = [
    google_service_account.workspace_service_accounts
  ]
}

