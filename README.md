# ImageTestEnv: EKS with Fargate HA

This branch is the manually operated AWS Kubernetes scenario. Terraform and
Terragrunt create an Amazon EKS cluster with Fargate profiles in two private
subnets. The application runs as two replicas with a PodDisruptionBudget and
zone spreading; there are no EC2 worker nodes in this scenario.

The NGINX Ingress Controller and the application are both scheduled on
Fargate. Terraform installs the controller with Helm. Ansible applies the
Kubernetes objects and waits for the application pods to become ready.

ECS has a separate Fargate Spot capacity option, but EKS Fargate pods cannot be
marked as Spot. This branch therefore uses standard EKS Fargate; the discounted
EC2 Spot alternative is implemented in `feature/eks-ec2-s3`.

## Requirements

- AWS CLI configured with permissions for EKS, EC2, IAM, and ELB
- Terraform 1.8.5+
- Terragrunt 0.67.16+
- Ansible
- `kubectl`
- Git
- A public GitHub Container Registry package, built by the manual workflow

Set `BUDGET_EMAIL` before running `./scripts/deploy.sh` to create an optional
monthly AWS Budget alert with a default threshold of USD 5. Leave it blank to
avoid creating the budget resource.

## Build the application image

The Kubernetes image contains the complete `html/` directory from `AI_Nginx`,
including audio. Build and publish it to the public GitHub Container Registry
package by starting the `Validate and Build Kubernetes Image` workflow manually
from the Actions tab. The workflow does not run on push.

`./scripts/deploy.sh` asks for an image tag. Use the workflow's commit SHA tag
for a reproducible deployment, or leave it as `latest` during development.

Docker Hub is not used by this repository. The GHCR image packages the files so
recreated pods receive the same site content without an interactive copy step.

## Create the environment

```bash
cd terraform-eks
terraform validate
terragrunt --working-dir ../terragrunt init
terragrunt --working-dir ../terragrunt plan
terragrunt --working-dir ../terragrunt apply
aws eks update-kubeconfig --region eu-central-1 \
  --name "$(terragrunt --working-dir ../terragrunt output -raw cluster_name)"
```

After confirming the AWS cost prompt, the complete apply, kubeconfig update and
Ansible deployment can be run with:

```bash
./scripts/deploy.sh
```

The EKS API endpoint is public for this demo and access is authenticated by
AWS IAM. Worker nodes run in private subnets and do not expose SSH. A bastion
is therefore not needed for this educational setup. For production, use a
private endpoint with a bastion host or AWS Systems Manager Session Manager.

## Deploy with Ansible

Ansible runs the deployment commands after Terraform and Terragrunt create the
cluster. Kubernetes remains responsible for scheduling and supervising the
nginx pods. The Deployment uses the published application image, so the files
remain available when Kubernetes recreates either pod.

```bash
ansible-playbook -i localhost, ../ansible/eks-deploy.yml
```

The playbook applies the namespace, Deployment, Service, and Ingress. Terraform
installs the NGINX Ingress Controller automatically in `ingress-nginx`.

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=available deployment/ingress-nginx-controller \
  --timeout=180s
kubectl get pods -n weather-demo
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Get the LoadBalancer hostname and test the host rule:

```bash
LOAD_BALANCER_HOST="$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
curl -H "Host: weather.local" "http://${LOAD_BALANCER_HOST}"
```

For browser testing without paid DNS, add the hostname to `/etc/hosts` after
resolving the LoadBalancer address, then open `http://weather.local`.

## Remove everything

Delete application objects first so the Ingress LoadBalancer can be released:

```bash
kubectl delete -f ../kubernetes/ --ignore-not-found
terragrunt --working-dir ../terragrunt destroy --non-interactive
```

The same cleanup is available as one confirmed command:

```bash
./scripts/destroy.sh
```

Terraform removes the EKS control plane, Fargate profiles, VPC, subnets, NAT
Gateway, route tables, Internet Gateway, security groups, and the Helm-installed
Ingress Controller.

Verify that the cluster and project VPC are gone:

```bash
aws eks list-clusters --region eu-central-1
aws ec2 describe-vpcs --region eu-central-1 \
  --filters 'Name=tag:Project,Values=image-test-env-eks'
```

The commands should return no project cluster and no project VPC. If the
LoadBalancer remains briefly, wait for AWS cleanup and check again.

## Repository structure

```text
├── kubernetes/
├── ansible/eks-deploy.yml
├── terragrunt/terragrunt.hcl
└── terraform-eks/
```

This branch is intentionally separate from the automatic EC2 workflow in
`main`, the three-node S3 scenario in `feature/eks-ec2-s3`, and the local WSL
scenario in `feature/local-kubernetes-wsl`.
