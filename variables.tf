
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


variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the state bucket"
  type        = string
  default     = "cw"
}

variable "gcp_service_account" {
  description = "GCP service account"
  type        = string
  default     = ""
}


variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}


variable "wi_pool_id" {
  description = "GCP workload identity pool ID"
  type        = string
  default     = ""
}


