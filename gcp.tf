
module "gcp_folder" {
  count = var.create_gcp_folder ? 1 : 0

  source = "git::https://github.com/cloudwalksolutions/terraform-google-folder.git?ref=0.0.19"

  parent_folder_id = var.gcp_parent_folder_id
  folder_name      = var.gcp_folder_name != "" ? var.gcp_folder_name : var.name
  projects_dict    = local.projects_to_create

  org_id = var.gcp_org_id

  create_service_account   = true
  sa_is_security_admin     = true
  sa_prefix                = var.gcp_sa_prefix
  sa_name                  = local.full_sa_name
  sa_project               = var.gcp_project_id
  extra_folder_permissions = var.gcp_service_account_permissions
}

# IAM permissions for service account in admin project
resource "google_project_iam_member" "admin_project_storage_admin" {
  count = var.allow_tf_workspaces && var.create_gcp_folder ? 1 : 0

  project = local.admin_project_name
  role    = "roles/storage.admin"
  member  = "serviceAccount:${local.sa_email}"

  depends_on = [module.gcp_folder]
}

resource "google_project_iam_member" "admin_project_iam_admin" {
  count = var.allow_tf_workspaces && var.create_gcp_folder ? 1 : 0

  project = local.admin_project_name
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${local.sa_email}"

  depends_on = [module.gcp_folder]
}

resource "google_project_iam_member" "admin_project_project_iam_admin" {
  count = var.allow_tf_workspaces && var.create_gcp_folder ? 1 : 0

  project = local.admin_project_name
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${local.sa_email}"

  depends_on = [module.gcp_folder]
}

