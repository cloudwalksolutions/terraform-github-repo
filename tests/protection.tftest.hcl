mock_provider "github" {}
mock_provider "google" {}

variables {
  name     = "widget-admin"
  org_name = "acme"
}

run "protects_with_classic_branch_protection_by_default" {
  command = plan

  assert {
    condition     = length(github_branch_protection_v3.branch_protections) == 1
    error_message = "main should keep classic protection"
  }

  assert {
    condition     = length(github_repository_ruleset.branch_protections) == 0
    error_message = "no ruleset unless asked for"
  }
}

run "lets_deploy_keys_past_a_ruleset_with_the_same_review_rules" {
  command = plan

  variables {
    protection_mode    = "ruleset"
    bypass_deploy_keys = true
  }

  assert {
    condition     = length(github_branch_protection_v3.branch_protections) == 0
    error_message = "classic protection would still block deploy keys"
  }

  assert {
    condition     = github_repository_ruleset.branch_protections["main"].bypass_actors[0].actor_type == "DeployKey"
    error_message = "deploy keys should bypass the ruleset"
  }

  assert {
    condition = (
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].required_approving_review_count == 1 &&
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].require_code_owner_review &&
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].dismiss_stale_reviews_on_push &&
      github_repository_ruleset.branch_protections["main"].rules[0].pull_request[0].required_review_thread_resolution &&
      github_repository_ruleset.branch_protections["main"].rules[0].non_fast_forward &&
      github_repository_ruleset.branch_protections["main"].rules[0].deletion
    )
    error_message = "the ruleset should keep classic protection's rules"
  }
}
