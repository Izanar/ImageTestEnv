# ImageTestEnv project context

Updated: 2026-09-04
Repository: https://github.com/Izanar/ImageTestEnv.git

## Local worktrees

- `/home/izanar/ImageTestEnv` -> `main`
- `/home/izanar/ImageTestEnv-fargate` -> `feature/eks-fargate-ha`
- `/home/izanar/ImageTestEnv-ec2-s3` -> `feature/eks-ec2-s3`
- `/home/izanar/ImageTestEnv-local-wsl` -> `feature/local-kubernetes-wsl`

All worktrees were clean at the time this file was created. Do not assume a
future worktree is clean; check `git status` before editing.

## Branch purposes

### main

Automatic temporary EC2 scenario without Kubernetes and without Docker runtime.
Terraform plus Terragrunt request one `t3.micro` EC2 Spot instance in the
default VPC. AWS assigns the public IP. Ansible installs nginx directly and
clones/copies `https://github.com/Izanar/AI_Nginx.git`. A push to `main` runs
`.github/workflows/aws-weather-deploy.yml`; the workflow attempts to destroy
the environment after 600 seconds. The workflow uses GitHub OIDC through the
`AWS_ROLE_ARN` secret, has a 30-minute timeout, verifies the AWS account, and
runs push cleanup with `always()`. A commit containing `[skip ci]` is used when
publishing documentation/configuration changes so that this workflow does not
run.

Terraform source: `terraform/`
Terragrunt: `terragrunt/terragrunt.hcl`
Ansible: `ansible/playbook.yml`
Launchers: `scripts/deploy.sh`, `scripts/destroy.sh`

### feature/eks-fargate-ha

Manual EKS scenario using standard EKS Fargate profiles, not EC2 worker nodes.
The application has two replicas, topology spread across zones, and a PDB.
NGINX Ingress Controller is installed by Terraform through Helm. Ansible
applies Kubernetes objects and copies files from `AI_Nginx` into every pod.
EKS Fargate Spot is not supported; ECS Fargate Spot is a different service.

Terraform source: `terraform-eks/`
Ansible: `ansible/eks-deploy.yml`
Launchers: `scripts/deploy.sh`, `scripts/destroy.sh`
Image: `ghcr.io/izanar/image-test-env-kubernetes`

### feature/eks-ec2-s3

Manual EKS scenario with three EC2 Spot worker nodes. Eligible types are
`t3.small` and `t3a.small`. Kubernetes runs three replicas with a PDB and an
AWS LoadBalancer supplied by the NGINX Ingress Controller. Terraform creates a
private encrypted versioned S3 bucket for audio and a CloudFront distribution
with Origin Access Control. Ansible syncs audio to S3 and copies non-audio
files from `AI_Nginx` into each pod.

Terraform source: `terraform-eks/`
Ansible: `ansible/eks-deploy.yml`
Launchers: `scripts/deploy.sh`, `scripts/destroy.sh`
Image: `ghcr.io/izanar/image-test-env-s3`

### feature/local-kubernetes-wsl

Local-only scenario. Terraform plus Terragrunt use the `null` provider and
local-exec scripts to install k3s in WSL when possible and configure a NodePort
network helper. There is one node and one nginx pod. Ansible clones `AI_Nginx`,
applies the Kubernetes resources, waits for the pod, and copies `html/` into the
pod. No AWS, S3, GHCR, or Docker image is required.

Terraform source: `terraform-local/`
Ansible: `ansible/local-deploy.yml`
Launchers: `scripts/deploy.sh`, `scripts/destroy.sh`

## Common commands

Run from the relevant worktree:

```bash
./scripts/deploy.sh
./scripts/destroy.sh
```

AWS launchers ask for region, expected account ID, optional budget email, an
explicit cost confirmation, and other scenario-specific values. EKS launchers
create/use an explicit kube-context before deployment and cleanup. WSL has no
AWS cost confirmation because it is local.

The launchers execute Terraform/Terragrunt plan/apply, kubeconfig setup and
Ansible. They have only been syntax-checked; no deploy script has been run in
this project session.

## Validation

```bash
terraform -chdir=terraform validate
terraform -chdir=terraform-eks validate
terraform -chdir=terraform-local validate
ansible-playbook --syntax-check -i localhost, ansible/eks-deploy.yml
ansible-playbook --syntax-check -i localhost, ansible/local-deploy.yml
bash -n scripts/*.sh
```

Use the path matching the current branch; the other Terraform directories may
not exist there.

## CI and cost guardrails

- `main` has the only AWS `push` workflow. Publishing to it must use
  `[skip ci]` unless an actual temporary deployment is intended.
- Feature workflows run on pull requests or manual dispatch; they do not have
  a `push` event.
- AWS credentials in the main workflow use OIDC and `AWS_ROLE_ARN`; the IAM
  role trust policy must restrict the GitHub repository/ref.
- Optional AWS Budgets are created only when `BUDGET_EMAIL` is non-empty, with
  a default monthly threshold of USD 5. Budget resources are not compute, but
  billing permissions are required.
- Terraform lock files are tracked at `terraform*/.terraform.lock.hcl`.
- Terraform state is still local; no remote backend has been introduced.
- NAT Gateway, EKS control plane, Fargate, LoadBalancer, CloudFront and S3 can
  incur charges even when compute uses Spot. Always destroy cloud scenarios
  after testing and inspect the AWS account for tagged leftovers.

## Image strategy

The AWS Kubernetes workflows build both `latest` and commit-SHA tags into GHCR.
The EKS launchers ask for an image tag and Ansible pins the deployment to that
tag; `latest` is the default. Docker Hub was not found or used. Images package
application files from `AI_Nginx` so recreated cloud pods have a repeatable
starting point. The EKS+S3 scenario deliberately keeps audio outside the image
in private S3 and serves it through CloudFront.

## Recent published HEADs

- `main`: `40ab353` - Harden EC2 workflow and lifecycle controls [skip ci]
- `feature/eks-fargate-ha`: `81c8f96` - Allow reproducible EKS image tags [skip ci]
- `feature/eks-ec2-s3`: `837d7a3` - Allow reproducible EKS S3 image tags [skip ci]
- `feature/local-kubernetes-wsl`: `9c5b37c` - Track WSL Terraform provider lock file [skip ci]

These values become stale after future commits; use `git log` and `git ls-remote`
to refresh them.

## Known follow-up considerations

- Verify the EKS Kubernetes version remains supported by AWS before applying.
- The main workflow cleanup cannot recover from a completely failed GitHub
  runner; inspect tagged resources if a run is interrupted.
- WSL2 LAN exposure may require a Windows Firewall inbound rule in addition to
  the portproxy helper.
- Do not run `terraform apply`, `terragrunt apply`, or a deploy launcher merely
  for validation. Use `fmt`, `init -backend=false`, `validate`, Ansible
  syntax-check, and shell syntax checks instead.
