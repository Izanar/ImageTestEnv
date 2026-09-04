#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
read -r -p "Remove the local Kubernetes application and k3s setup? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

if command -v kubectl >/dev/null; then
  kubectl delete -f kubernetes/ --ignore-not-found || true
fi
terragrunt --working-dir terragrunt destroy --non-interactive --auto-approve
