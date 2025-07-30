
resource "github_repository" "repo" {
  name        = var.name
  description = var.description

  auto_init   = true
  visibility  = var.repo_visibility
  is_template = var.is_template

  vulnerability_alerts = var.vulnerability_alerts

  allow_auto_merge       = var.allow_auto_merge
  delete_branch_on_merge = var.delete_branch_on_merge
  allow_update_branch    = var.allow_update_branch

  dynamic "template" {
    for_each = local.template
    content {
      owner      = var.org_name
      repository = template.value
    }
  }

  dynamic "pages" {
    for_each = var.enable_github_pages && var.repo_visibility == "public" ? var.github_pages : toset([])

    content {
      source {
        branch = pages.value.branch
        path   = pages.value.path
      }
    }
  }

  lifecycle {
    ignore_changes = [description]
  }

}

resource "github_actions_repository_access_level" "actions_access" {
  count = var.repo_visibility == "private" ? 1 : 0

  access_level = var.actions_access_level
  repository   = github_repository.repo.name
}


resource "github_team_repository" "team_repo" {
  count = var.team_id != "" ? 1 : 0

  team_id    = var.team_id
  repository = github_repository.repo.name
  permission = var.permission

  depends_on = [
    github_repository.repo,
  ]
}


resource "github_repository_dependabot_security_updates" "dependabot" {
  repository = github_repository.repo.name
  enabled    = var.vulnerability_alerts
}


resource "github_branch" "branches" {
  for_each = toset(setsubtract(var.extra_lifecycles, [var.source_branch, "main", "prod"]))

  repository    = github_repository.repo.name
  branch        = each.key == "prod" ? var.source_branch : each.key
  source_branch = var.source_branch

  depends_on = [
    github_repository.repo,
  ]
}


resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch     = var.source_branch

  depends_on = [
    github_repository.repo,
    github_branch.branches,
  ]
}


resource "github_branch_protection_v3" "branch_protections" {
  for_each = var.protect_branches ? local.all_branches : toset([])

  repository = github_repository.repo.name

  branch                          = each.key == "prod" ? "main" : each.key
  enforce_admins                  = each.key == var.source_branch ? var.enforce_admins : false
  require_conversation_resolution = var.require_conversation_resolution

  # required_status_checks {
  #   strict   = false
  #   contexts = ["ci/travis"]
  # }

  required_pull_request_reviews {
    dismiss_stale_reviews      = true
    require_code_owner_reviews = true
    dismissal_users            = var.dismissal_restrictions
    dismissal_teams            = []
  }

  restrictions {
    users = var.push_restrictions
    teams = []
    apps  = []
  }

  depends_on = [
    github_branch.branches,
  ]
}

