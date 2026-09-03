# ImageTestEnv: EKS

This branch contains only the manual AWS Kubernetes scenario. It creates an
Amazon EKS cluster, one Spot worker node, an NGINX Ingress Controller, and a
private S3 bucket for audio files from `AI_Nginx`.

## Requirements

- AWS CLI configured with permissions for EKS, EC2, IAM, S3, and ELB
- Terraform 1.8.5+
- `kubectl`
- Git

## Create the environment

```bash
cd terraform-eks
terraform init
terraform validate
terraform plan
terraform apply
aws eks update-kubeconfig --region eu-central-1 --name "$(terraform output -raw cluster_name)"
```

The EKS API endpoint is public for this demo and access is authenticated by
AWS IAM. Worker nodes run in private subnets and do not expose SSH. A bastion
is therefore not needed for this educational setup. For production, use a
private endpoint with a bastion host or AWS Systems Manager Session Manager.

## Load the audio and deploy

The S3 bucket is private. Sync audio from the public `AI_Nginx` repository:

```bash
../scripts/sync-audio-to-s3.sh \
  https://github.com/Izanar/AI_Nginx.git \
  "$(terraform output -raw audio_bucket_name)"
```

The source repository must contain an `audio/` directory. The Kubernetes pod
uses IRSA with read-only access to `audio/*`. Its init container downloads the
objects into an internal volume, so clients reach the files through the nginx
Ingress at `/audio/` without direct S3 access.

```bash
kubectl apply -f ../kubernetes/namespace.yaml
kubectl apply -f ../kubernetes/deployment.yaml
kubectl apply -f ../kubernetes/service.yaml
kubectl apply -f ../kubernetes/ingress.yaml

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
curl -H "Host: weather.local" "http://${LOAD_BALANCER_HOST}/audio/"
```

## Remove everything

Delete application objects first so the Ingress LoadBalancer can be released:

```bash
kubectl delete -f ../kubernetes/ --ignore-not-found
terraform destroy
```

Terraform then removes the EKS control plane, Spot node group, IAM/IRSA
resources, private S3 bucket, VPC, subnets, NAT Gateway, route tables,
Internet Gateway, security groups, and Helm-installed Ingress Controller.

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
├── scripts/sync-audio-to-s3.sh
└── terraform-eks/
```

This branch is intentionally separate from the cheap push-triggered EC2
workflow in `main`.
