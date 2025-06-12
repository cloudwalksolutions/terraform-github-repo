package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

var tfDir = "../"

func TestRepoModule(t *testing.T) {
	input, err := os.ReadFile("./provider.tf")
	if err != nil {
		t.Fatalf("Failed to read providers.tf: %v", err)
	}

	destFilePath := tfDir + "provider.tf"
	if err = os.WriteFile(destFilePath, input, 0o644); err != nil {
		t.Fatalf("Failed to write providers.tf to destination: %v", err)
	}

	if err := os.Remove("./provider.tf"); err != nil {
		t.Fatalf("Failed to delete providers.tf: %v", err)
	}

	defer func() {
		if err = os.WriteFile("./provider.tf", input, 0o644); err != nil {
			t.Fatalf("Failed to write providers.tf to destination: %v", err)
		}

		if err := os.Remove(destFilePath); err != nil {
			t.Fatalf("Failed to delete providers.tf: %v", err)
		}
	}()

	opts := &terraform.Options{
		TerraformDir: tfDir,
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
