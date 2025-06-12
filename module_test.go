package test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

const authProviderBlock = `
provider "github" {
  owner = var.github_org
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = file(var.github_app_private_key_path)
  }
}
`

func TestRepoModule(t *testing.T) {
	providerFile := "provider.tf"

	tmpDir, err := os.MkdirTemp("", "terratest-tmp")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	originalContents, err := os.ReadFile(providerFile)
	if err != nil {
		t.Fatalf("Failed to read provider.tf: %v", err)
	}

	tmpFile := filepath.Join(tmpDir,providerFile)
	if err := os.WriteFile(tmpFile, originalContents, 0o644); err != nil {
		t.Fatalf("Failed to write to temp provider.tf: %v", err)
	}

	f, err := os.OpenFile(providerFile, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		t.Fatalf("Failed to open temp provider.tf for appending: %v", err)
	}
	defer f.Close()

	if _, err := f.WriteString(authProviderBlock); err != nil {
		t.Fatalf("Failed to append provider block: %v", err)
	}

	defer func() {
		if err := os.WriteFile(providerFile, originalContents, 0o644); err != nil {
			t.Fatalf("Failed to restore original provider.tf: %v", err)
		}
	}()

	opts := &terraform.Options{
		TerraformDir: ".",
		EnvVars:      map[string]string{},
		Vars: map[string]interface{}{
			"org_name":            "cloudwalk",
			"name":                "test-repo",
			"description":         "Test repository for CloudWalk",
			"repo_visibility":     "public",
			"enable_github_pages": true,
			"github_pages": map[string]interface{}{
				"main": "/",
			},
		},
	}
	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	repoName := terraform.Output(t, opts, "repo_name")
	expectedRepoName := "test-repo"
	if repoName != expectedRepoName {
		t.Fatalf("Expected repo name to be '%s', but got '%s'", expectedRepoName, repoName)
	}
}
