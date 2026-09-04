#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required" >&2; exit 1; }
read -r -p "AWS region [eu-central-1]: " aws_region
aws_region="${aws_region:-eu-central-1}"
read -r -p "Expected AWS account ID (optional): " expected_account_id
actual_account_id="$(aws sts get-caller-identity --query Account --output text)"
echo "Using AWS account: ${actual_account_id}"
if [[ -n "$expected_account_id" && "$expected_account_id" != "$actual_account_id" ]]; then
  echo "AWS account mismatch; refusing to continue." >&2
  exit 1
fi
read -r -p "Destroy the EKS/Fargate environment and its LoadBalancer? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

cluster_name="$(terragrunt --working-dir terragrunt output -raw cluster_name 2>/dev/null || true)"
if [[ -n "$cluster_name" ]]; then
  context="image-test-env-${cluster_name}"
  aws eks update-kubeconfig --region "$aws_region" --name "$cluster_name" --alias "$context" >/dev/null 2>&1 || true
  kubectl --context "$context" delete -f kubernetes/ --ignore-not-found || true
fi
terragrunt --working-dir terragrunt destroy --non-interactive --auto-approve -var="aws_region=${aws_region}"
