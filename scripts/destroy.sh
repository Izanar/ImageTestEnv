#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
read -r -p "AWS region [eu-central-1]: " aws_region
aws_region="${aws_region:-eu-central-1}"
read -r -p "Destroy EKS, three Spot nodes, S3 audio and CloudFront? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

if command -v kubectl >/dev/null; then
  kubectl delete -f kubernetes/ --ignore-not-found || true
fi
terragrunt --working-dir terragrunt destroy --non-interactive --auto-approve -var="aws_region=${aws_region}"
