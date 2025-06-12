
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_org
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = file(var.github_app_private_key_path)
  }
}

