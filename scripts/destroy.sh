#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }
read -r -p "AWS region [eu-central-1]: " aws_region
aws_region="${aws_region:-eu-central-1}"
read -r -p "Expected AWS account ID (optional): " expected_account_id
actual_account_id="$(aws sts get-caller-identity --query Account --output text)"
echo "Using AWS account: ${actual_account_id}"
if [[ -n "$expected_account_id" && "$expected_account_id" != "$actual_account_id" ]]; then
  echo "AWS account mismatch; refusing to continue." >&2
  exit 1
fi
read -r -p "SSH public key path [$HOME/.ssh/id_rsa.pub]: " public_key_path
public_key_path="${public_key_path:-$HOME/.ssh/id_rsa.pub}"
read -r -p "Destroy all Terraform-managed main resources? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

terragrunt --working-dir terragrunt destroy --non-interactive --auto-approve \
  -var="aws_region=${aws_region}" \
  -var="public_key_path=${public_key_path}"
