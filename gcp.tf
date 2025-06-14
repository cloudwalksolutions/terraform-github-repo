
module "gcp_folder" {
  count = var.create_gcp_folder ? 1 : 0

  source = "git::https://github.com/cloudwalksolutions/terraform-google-folder.git?ref=0.0.19"

  parent_folder_id = var.gcp_parent_folder_id
  folder_name      = var.gcp_folder_name != "" ? var.gcp_folder_name : var.name
  projects_dict    = var.gcp_projects_to_create

  org_id = var.gcp_org_id

  create_service_account   = true
  sa_is_security_admin     = true
  sa_prefix                = var.gcp_sa_prefix
  sa_name                  = local.full_sa_name
  sa_project               = var.gcp_project_id
  extra_folder_permissions = var.gcp_service_account_permissions
}

