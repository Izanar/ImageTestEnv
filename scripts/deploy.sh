#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
command -v ansible-playbook >/dev/null || { echo "ansible-playbook is required" >&2; exit 1; }

read -r -p "Install/update local k3s and deploy one nginx pod in WSL? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

terragrunt --working-dir terragrunt init
terragrunt --working-dir terragrunt apply --auto-approve
ansible-playbook -i localhost, ansible/local-deploy.yml
kubectl get nodes
kubectl get pods -n weather-demo -o wide
printf 'Application URL: http://127.0.0.1:30080\n'
