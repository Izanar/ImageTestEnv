# ImageTestEnv: automatic EC2 demo

This `main` branch contains one scenario: a push-triggered, short-lived AWS
EC2 environment. GitHub Actions creates the instance with Terraform, uses
Ansible to install and configure nginx, verifies the application, and destroys
the infrastructure after 10 minutes.

Terragrunt is the workflow entry point for the EC2 Terraform module. Terraform
defines resources, Terragrunt supplies environment defaults, and Ansible
configures the created instance.

The Kubernetes scenarios are maintained separately in
`feature/eks-fargate-ha`, `feature/eks-ec2-s3`, and
`feature/local-kubernetes-wsl`.

## Requirements

Configure these GitHub repository secrets:

- `AWS_ROLE_ARN` for GitHub Actions OIDC
- `AWS_SSH_PRIVATE_KEY`
- `AWS_SSH_PUBLIC_KEY`
- optional `USER_PUBLIC_IP`

The AWS role must trust GitHub's OIDC provider for this repository and be
allowed to manage the EC2 resources used by this workflow. Terraform 1.8.5+,
Terragrunt 0.67.16+, and Ansible are installed by the workflow runner.

Set `BUDGET_EMAIL` locally to enable the optional AWS Budget alert. A budget
does not create compute resources, but AWS Billing permissions are required.

## Automatic deployment

A push to `main` starts the workflow
[AWS Weather Deploy](.github/workflows/aws-weather-deploy.yml). It performs
these steps:

1. Validates Terraform.
2. Terragrunt requests one `t3.micro` Spot Ubuntu EC2 instance in the default VPC;
    AWS assigns its public IP automatically.
3. Opens SSH only to the GitHub runner IP and optional `USER_PUBLIC_IP`.
4. Waits for SSH readiness.
5. Ansible installs nginx, clones `AI_Nginx`, and publishes its `html/` folder.
6. An HTTP smoke test checks the page.
7. Terragrunt destroys the instance and related resources after 10 minutes.

This branch deliberately does not build or run a Docker container. The EC2
instance is a normal Ubuntu server, and Ansible installs nginx directly and
copies the required files from the `Izanar/AI_Nginx` repository. The image
workflows in the Kubernetes branches exist to package the same application for
Kubernetes pods; they are not used by this branch.

HTTP and HTTPS are public for this demo. SSH is limited to the runner and the
optional user IP.

## One-command local control

The same workflow can be run from this checkout with prompts for the AWS
region, SSH key and confirmation:

```bash
./scripts/deploy.sh
./scripts/destroy.sh
```

## Run manually

The normal trigger is a push to `main`. To apply or destroy from GitHub Actions:

1. Open **Actions** in the repository.
2. Select **AWS Weather Deploy**.
3. Select **Run workflow**.
4. Choose `apply` or `destroy`.
5. Choose the AWS region.

The `apply` action creates the instance and configures nginx through Ansible.
The `destroy` action removes the Terraform-managed instance and networking
resources from the current state.

## Local validation

```bash
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
ansible-playbook --syntax-check -i ansible/inventory.ini ansible/playbook.yml
```

## Repository structure

```text
├── .github/workflows/aws-weather-deploy.yml
├── ansible/
│   ├── inventory.ini
│   └── playbook.yml
├── terragrunt/terragrunt.hcl
└── terraform/
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    └── versions.tf
```

This branch is intentionally focused on a cheap CI/CD infrastructure demo.
Every push creates a fresh environment and the workflow attempts to delete it
after 600 seconds. A cancelled workflow or runner failure can interrupt that
cleanup, so the manual `destroy` action remains available. This is not a
production deployment template. Spot capacity can be interrupted by AWS before
the ten-minute cleanup, so the workflow may fail before the smoke test.
