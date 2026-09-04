#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }
command -v ansible-playbook >/dev/null || { echo "ansible-playbook is required" >&2; exit 1; }
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
read -r -p "Budget alert email (optional; leave blank to disable): " budget_email
export BUDGET_EMAIL="$budget_email"
read -r -p "This creates a billable EKS/Fargate environment. Continue? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

terragrunt --working-dir terragrunt init
terragrunt --working-dir terragrunt plan -var="aws_region=${aws_region}"
terragrunt --working-dir terragrunt apply --auto-approve -var="aws_region=${aws_region}"
cluster_name="$(terragrunt --working-dir terragrunt output -raw cluster_name)"
context="image-test-env-${cluster_name}"
aws eks update-kubeconfig --region "$aws_region" --name "$cluster_name" --alias "$context"
kubectl config use-context "$context" >/dev/null
ansible-playbook -i localhost, ansible/eks-deploy.yml
kubectl get pods -n weather-demo -o wide
