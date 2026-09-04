#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
command -v terragrunt >/dev/null || { echo "terragrunt is required" >&2; exit 1; }
command -v ansible-playbook >/dev/null || { echo "ansible-playbook is required" >&2; exit 1; }

read -r -p "AWS region [eu-central-1]: " aws_region
aws_region="${aws_region:-eu-central-1}"
read -r -p "SSH public key path [$HOME/.ssh/id_rsa.pub]: " public_key_path
public_key_path="${public_key_path:-$HOME/.ssh/id_rsa.pub}"
read -r -p "Your public IPv4/CIDR for SSH (optional; not the instance IP): " user_public_ip
read -r -p "This creates a billable AWS Spot EC2 instance. Continue? [yes/no]: " confirmation
[[ "$confirmation" == "yes" ]] || { echo "Cancelled."; exit 0; }

runner_ip="$(curl -fsSL https://api.ipify.org)"
ssh_cidrs="[\"${runner_ip}/32\""
if [[ -n "$user_public_ip" ]]; then
  [[ "$user_public_ip" == */* ]] || user_public_ip+="/32"
  ssh_cidrs+=" ,\"${user_public_ip}\""
fi
ssh_cidrs+="]"

terragrunt --working-dir terragrunt init
terragrunt --working-dir terragrunt apply --auto-approve \
  -var="aws_region=${aws_region}" \
  -var="public_key_path=${public_key_path}" \
  -var="ssh_cidr_blocks=${ssh_cidrs}"

public_ip="$(terragrunt --working-dir terragrunt output -raw public_ip)"
cat > /tmp/image-test-env-inventory.ini <<EOF
[webservers]
web1 ansible_host=${public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${public_key_path%.*} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
ansible-playbook -i /tmp/image-test-env-inventory.ini ansible/playbook.yml
printf 'Application URL: http://%s\n' "$public_ip"
