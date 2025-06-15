# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Module

This is a Terraform module for creating and managing GitHub repositories with comprehensive features including branch protection, team permissions, GitHub Pages, and optional GCP integrations for workload identity and state management.

## Commands

### Testing
- `go test -v` - Run the Terratest Go tests
- `go mod tidy` - Clean up Go module dependencies

### Terraform Operations
- `terraform init` - Initialize Terraform (requires GitHub provider configuration)
- `terraform plan` - Preview changes
- `terraform apply` - Apply changes
- `terraform destroy` - Destroy resources

## Architecture

### Core Components

**Main Resources (main.tf)**:
- `github_repository` - Primary repository with template support, pages, visibility settings
- `github_actions_repository_access_level` - Controls Actions access for private repos
- `github_team_repository` - Team permissions assignment
- `github_repository_dependabot_security_updates` - Automated security updates
- `github_branch` - Additional branch creation
- `github_branch_default` - Default branch configuration
- `github_branch_protection_v3` - Branch protection rules with PR reviews and restrictions

**GCP Integration (gcp.tf, workspace.tf)**:
- Optional GCP folder creation via external module
- Terraform state bucket in GCS with versioning
- Workload Identity setup for GitHub Actions
- Service account creation with proper IAM bindings
- GitHub Actions variables and secrets for GCP integration

**Key Locals (locals.tf)**:
- `template` - Conditional template repository reference  
- `all_branches` - Combined list of source and new branches
- `gcp_workload_identity_*` - Workload Identity configuration strings
- `state_bucket_name` - Standardized bucket naming

### Testing Strategy

The module uses Terratest (Go) for integration testing. The test:
1. Temporarily modifies `provider.tf` to add GitHub App authentication
2. Creates a test repository with GitHub Pages enabled
3. Validates the repository name output
4. Cleans up by restoring original provider configuration

### Configuration Patterns

- **Branch Protection**: Automatically protects all branches when `protect_branches=true`
- **Template Support**: Uses dynamic blocks for conditional template repository setup
- **GCP Integration**: Controlled by `allow_tf_workspaces` flag for optional cloud resources
- **GitHub Pages**: Only enabled for public repositories with `enable_github_pages=true`