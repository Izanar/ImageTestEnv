# ImageTestEnv

In this repository there are two scenarios:

1. Manual EKS path — a manual setup for a real Kubernetes environment
2. Push-triggered EC2 path — an automatic setup for a cheap and fast demo

## 1. Manual variant: EKS

This is the correct Kubernetes option. It shows how to create an EKS cluster in a real project and deploy an application.

Files:

- [terraform-eks/main.tf](terraform-eks/main.tf)
- [terraform-eks/variables.tf](terraform-eks/variables.tf)
- [terraform-eks/outputs.tf](terraform-eks/outputs.tf)
- [kubernetes/namespace.yaml](kubernetes/namespace.yaml)
- [kubernetes/deployment.yaml](kubernetes/deployment.yaml)
- [kubernetes/service.yaml](kubernetes/service.yaml)
- [kubernetes/ingress.yaml](kubernetes/ingress.yaml)

How to run it manually:

```bash
cd terraform-eks
terraform init
terraform validate
terraform plan
terraform apply
```

After apply, update the kubeconfig:

```bash
aws eks update-kubeconfig --region eu-central-1 --name $(terraform output -raw cluster_name)
```

Then deploy the app:

```bash
kubectl apply -f ../kubernetes/namespace.yaml
kubectl apply -f ../kubernetes/deployment.yaml
kubectl apply -f ../kubernetes/service.yaml
kubectl apply -f ../kubernetes/ingress.yaml
```

Check the workload:

```bash
kubectl get pods -n weather-demo
kubectl get svc -n weather-demo
```

Destroy the cluster when finished:

```bash
terraform destroy
```

## 2. Automatic variant: EC2 after push

This is the cheap CI/CD demo flow. It creates a short-lived EC2 instance, configures nginx with Ansible, verifies the app, and destroys the environment automatically after 10 minutes.

Files:

- [.github/workflows/aws-weather-deploy.yml](.github/workflows/aws-weather-deploy.yml)
- [terraform/main.tf](terraform/main.tf)
- [terraform/variables.tf](terraform/variables.tf)
- [terraform/outputs.tf](terraform/outputs.tf)
- [ansible/playbook.yml](ansible/playbook.yml)

How it works:

1. A push to `main` triggers the workflow.
2. Terraform creates one EC2 instance.
3. Ansible installs nginx and deploys the app.
4. A smoke test verifies the page is reachable over HTTP.
5. The instance is destroyed automatically after 10 minutes.

This is the cheapest practical demo to show infrastructure automation without keeping AWS resources running forever.

## Manual destroy

The EC2 demo can also be destroyed manually from GitHub Actions:

1. Open the repository in GitHub.
2. Go to Actions.
3. Select the workflow `AWS Weather Deploy`.
4. Click `Run workflow`.
5. Set `action` to `destroy` and start it.

You can also trigger it from the CLI:

```bash
gh workflow run "AWS Weather Deploy" \
  -f action=destroy \
  -f region=eu-central-1
```

## Terragrunt

The file [terragrunt/terragrunt.hcl](terragrunt/terragrunt.hcl) is a thin Terraform wrapper, not a separate deployment system. It keeps shared defaults and environment values in one place.

## Requirements

- AWS account
- Terraform 1.8.5+
- AWS CLI configured
- GitHub secrets for AWS access and SSH keys
- `kubectl` for the EKS flow
- Optional Terragrunt for the wrapper flow

## Repository structure

```text
ImageTestEnv/
├── .github/
│   └── workflows/
│       └── aws-weather-deploy.yml
├── ansible/
│   └── playbook.yml
├── kubernetes/
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── terraform-eks/
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── terragrunt/
│   └── terragrunt.hcl
├── .gitignore
├── README.md
└── .gitignore
```

## Summary

This repository is a small DevOps sandbox for:

- infrastructure as code
- automation with Terraform and Ansible
- CI/CD with GitHub Actions
- manual EKS deployment
- short-lived EC2 demo environments with automatic cleanup

It is meant for learning, demos, and experimentation rather than production deployment.
