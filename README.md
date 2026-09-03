# ImageTestEnv: EKS

This branch contains only the manual AWS Kubernetes scenario. It creates an
Amazon EKS cluster, one Spot worker node, and an NGINX Ingress Controller.
There is no S3 storage in this branch.

## Requirements

- AWS CLI configured with permissions for EKS, EC2, IAM, and ELB
- Terraform 1.8.5+
- Terragrunt 0.67.16+
- Ansible
- `kubectl`
- Git

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

The EKS API endpoint is public for this demo and access is authenticated by
AWS IAM. Worker nodes run in private subnets and do not expose SSH. A bastion
is therefore not needed for this educational setup. For production, use a
private endpoint with a bastion host or AWS Systems Manager Session Manager.

## Deploy with Ansible

Ansible runs the deployment commands after Terraform and Terragrunt create the
cluster. Kubernetes remains responsible for scheduling and supervising the
nginx pod. Ansible clones `AI_Nginx`, waits for the pod, and copies its complete
`html/` directory into the nginx document root.

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

## Remove everything

Delete application objects first so the Ingress LoadBalancer can be released:

```bash
kubectl delete -f ../kubernetes/ --ignore-not-found
terragrunt --working-dir ../terragrunt destroy --non-interactive
```

Terraform removes the EKS control plane, Spot node group, VPC, subnets, NAT
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
`main` and from the S3 audio variant in `feature/eks-s3-audio`.
