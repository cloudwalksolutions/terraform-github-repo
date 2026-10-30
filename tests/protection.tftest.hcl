mock_provider "github" {}
mock_provider "google" {}

variables {
  name     = "widget-admin"
  org_name = "acme"
}

run "protects_main_with_a_ruleset_requiring_a_code_owner_review" {
  command = plan

  assert {
    condition = (
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].required_approving_review_count == 1 &&
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].require_code_owner_review &&
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].dismiss_stale_reviews_on_push &&
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].required_review_thread_resolution &&
      github_repository_ruleset.branch_protections["main"].rules[0].non_fast_forward &&
      github_repository_ruleset.branch_protections["main"].rules[0].deletion
    )
    error_message = "main should need a code owner's review and refuse force pushes and deletion"
  }

  assert {
    condition = anytrue([
      for actor in github_repository_ruleset.branch_protections["main"].bypass_actors :
      actor.actor_type == "RepositoryRole" && actor.actor_id == 5 && actor.bypass_mode == "always"
    ])
    error_message = "repo admins should still push and merge past review"
  }

  assert {
    condition = alltrue([
      for actor in github_repository_ruleset.branch_protections["main"].bypass_actors :
      actor.actor_type != "DeployKey"
    ])
    error_message = "deploy keys should push past review only when asked"
  }
}

run "lets_deploy_keys_push_when_asked" {
  command = plan

  variables {
    bypass_deploy_keys = true
  }

  assert {
    condition = anytrue([
      for actor in github_repository_ruleset.branch_protections["main"].bypass_actors :
      actor.actor_type == "DeployKey" && actor.bypass_mode == "always"
    ])
    error_message = "deploy keys should bypass the ruleset"
  }
}
