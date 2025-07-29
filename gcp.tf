
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

module "admin_project_iam" {
  count = var.allow_tf_workspaces && var.create_gcp_folder ? 1 : 0

  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 8.1"

  projects = [local.admin_project_id]

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

