
variable "parent_team_id" {
  description = "Github parent ID"
  type        = string
  default     = ""
}


variable "name" {
  description = "Github repository name"
  type        = string
}


variable "repo_visibility" {
  description = "Repo visibility: private/public"
  type        = string
  default     = "private"
}


variable "org_name" {
  description = "Github org"
  type        = string
}


variable "template_repo" {
  description = "Github repo template"
  type        = string
  default     = ""
}


variable "permission" {
  description = "Github default member permissions"
  type        = string
  default     = "pull"
}


variable "team_id" {
  description = "Github team ID"
  type        = string
  default     = ""
}


variable "description" {
  description = "Github repo description"
  type        = string
  default     = ""
}


variable "source_branch" {
  description = "Source branch for repo"
  type        = string
  default     = "main"
}


variable "new_branches" {
  description = "List of new branches"
  type        = list(string)
  default     = []
}


variable "is_template" {
  description = "Whether repo should be template"
  type        = bool
  default     = false
}


variable "protect_branches" {
  description = "Whether repo should protect initial branches"
  type        = bool
  default     = true
}


variable "allow_tf_workspaces" {
  description = "Whether repo should allow for TF workspaces"
  type        = bool
  default     = false
}


variable "tfstate_buckets" {
  description = "List of GCP buckets to use for Terraform state"
  type        = list(string)
  default     = []
}


variable "auto_apply" {
  description = "Whether to automatically apply changes when a Terraform plan is successful."
  default     = true
}


variable "dismissal_restrictions" {
  description = "List of people who can dismiss restrictions on pull requests"
  type        = list(string)
  default     = []
}


variable "push_restrictions" {
  description = "List of people who can dismiss push restrictions"
  type        = list(string)
  default     = []
}


variable "vulnerability_alerts" {
  description = "Whether repo should enable vulnerability alerts"
  type        = bool
  default     = true
}


variable "allow_auto_merge" {
  description = "Whether repo should allow for auto merges"
  type        = bool
  default     = true
}


variable "delete_branch_on_merge" {
  description = "Whether repo automatically delete unprotected branches when PR is merged"
  type        = bool
  default     = true
}


variable "allow_update_branch" {
  description = "Whether repo should suggest updating PR branches"
  type        = bool
  default     = true
}


variable "required_status_checks" {
  description = "List of required status checks"
  type        = list(string)
  default     = []
}


variable "require_conversation_resolution" {
  description = "Whether to require conversation resolution before merging"
  type        = bool
  default     = true
}


variable "enforce_admins" {
  description = "Whether to enforce branch protection for admins"
  type        = bool
  default     = false
}


variable "is_github_admin" {
  description = "Whether to use Github admin credentials"
  type        = bool
  default     = false
}


variable "github_app_id" {
  description = "Github app ID"
  type        = string
  default     = ""
}


variable "github_app_installation_id" {
  description = "Github app installation ID"
  type        = string
  default     = ""
}


variable "github_app_private_key" {
  description = "Github app private key"
  type        = string
  default     = ""
}


variable "gcp_billing_account_id" {
  description = "GCP billing account ID"
  type        = string
  default     = ""
}


variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}


variable "state_bucket_prefix" {
  description = "Prefix for the state bucket"
  type        = string
  default     = "cws"
}


variable "state_bucket_prefix_legacy" {
  description = "Legacy Prefix for the state bucket"
  type        = string
  default     = "cw"
}


variable "admin_project_prefix" {
  description = "Prefix for the admin project"
  type        = string
  default     = ""
}


variable "gcp_sa_prefix" {
  description = "GCP service account prefix"
  type        = string
  default     = ""
}


variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}


variable "workspace_project_id" {
  description = "GCP project ID for the TF workspace"
  type        = string
  default     = ""
}


variable "gcp_parent_folder_id" {
  description = "GCP parent folder ID"
  type        = string
  default     = ""
}


variable "create_gcp_folder" {
  description = "Whether to create a GCP folder for the project"
  type        = bool
  default     = false
}


variable "gcp_folder_name" {
  description = "GCP folder name to create. If not set, will use the name variable"
  type        = string
  default     = ""
}


variable "gcp_projects_to_create" {
  description = "Map of GCP projects to create to list of APIs to enable"
  type        = map(list(string))
  default     = {}
}


variable "actions_access_level" {
  description = "Access level for GitHub Actions in the repository. Options are 'none', 'user', 'organization', 'enterprise'. Default is 'none'."
  type        = string
  default     = "none"
}


variable "enable_github_pages" {
  description = "Whether to enable GitHub Pages for the repository"
  type        = bool
  default     = false
}


variable "github_pages" {
  description = "Map of GitHub Pages branches to their source directories"
  type = list(object({
    branch = string
    path   = string
  }))
  default = []
}

variable "gcp_org_id" {
  description = "GCP organization ID"
  type        = string
  default     = ""
}


variable "gcp_service_account_permissions" {
  description = "List of GCP service account permissions to assign to the folder admin. These should be the role names without the 'roles/' prefix."
  type        = list(string)
  default     = []
}


variable "workload_identity_pool_id" {
  description = "Workload Identity Pool ID for GitHub Actions"
  type        = string
  default     = ""
}


variable "create_workload_identity_pool" {
  description = "Whether to create a Workload Identity Pool for GitHub Actions"
  type        = bool
  default     = true
}


variable "create_workload_identity_pool_provider" {
  description = "Whether to create a Workload Identity Pool Provider for GitHub Actions"
  type        = bool
  default     = true
}


