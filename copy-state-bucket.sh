#!/bin/bash

# Script to copy Terraform state from v1 bucket to v2 bucket
# Usage: ./copy-state-bucket.sh <repo-name> [v1-prefix] [v2-prefix]

set -e

# Default prefixes from the Terraform module
DEFAULT_V1_PREFIX="cw"
DEFAULT_V2_PREFIX="cws"

# Parse arguments
REPO_NAME="$1"
V1_PREFIX="${2:-$DEFAULT_V1_PREFIX}"
V2_PREFIX="${3:-$DEFAULT_V2_PREFIX}"

# Validate required argument
if [ -z "$REPO_NAME" ]; then
    echo "Error: Repository name is required"
    echo "Usage: $0 <repo-name> [v1-prefix] [v2-prefix]"
    echo "Example: $0 my-terraform-repo"
    echo "Example: $0 my-terraform-repo custom-v1 custom-v2"
    exit 1
fi

# Construct bucket names
V1_BUCKET="${V1_PREFIX}-${REPO_NAME}-tfstate"
V2_BUCKET="${V2_PREFIX}-${REPO_NAME}-tfstate"

echo "Copying Terraform state from v1 to v2 bucket:"
echo "  Source: gs://${V1_BUCKET}"
echo "  Target: gs://${V2_BUCKET}"
echo

# Check if source bucket exists
if ! gsutil ls "gs://${V1_BUCKET}" > /dev/null 2>&1; then
    echo "Error: Source bucket gs://${V1_BUCKET} does not exist or is not accessible"
    exit 1
fi

# Check if target bucket exists
if ! gsutil ls "gs://${V2_BUCKET}" > /dev/null 2>&1; then
    echo "Error: Target bucket gs://${V2_BUCKET} does not exist or is not accessible"
    exit 1
fi

# List contents of source bucket
echo "Contents of source bucket:"
gsutil ls -r "gs://${V1_BUCKET}" || echo "Source bucket is empty"
echo

# Copy all objects from v1 to v2 bucket
echo "Starting copy operation..."
gsutil -m cp -r "gs://${V1_BUCKET}/*" "gs://${V2_BUCKET}/" || {
    echo "Warning: Copy operation completed with some files possibly missing"
    echo "This might be normal if the source bucket is empty"
}

echo
echo "Copy operation completed!"
echo

# Verify the copy by listing target bucket contents
echo "Contents of target bucket after copy:"
gsutil ls -r "gs://${V2_BUCKET}" || echo "Target bucket appears empty"

echo
echo "State migration complete for repository: ${REPO_NAME}"