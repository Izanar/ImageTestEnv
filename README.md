# ImageTestEnv: EKS

This branch contains only the manual AWS Kubernetes scenario. It creates an
Amazon EKS cluster, one Spot worker node, an NGINX Ingress Controller, and a
private S3 bucket for audio files from `AI_Nginx`.

## Requirements

- AWS CLI configured with permissions for EKS, EC2, IAM, S3, and ELB
- Terraform 1.8.5+
- Terragrunt 0.67.16+
- Ansible
- `kubectl`
- Git
- A public GitHub Container Registry package, built by the manual workflow

## Build the application image

The S3 image contains `index.html`, `script.js`, and `style.css`, but no audio.
Build and publish it to the public GitHub Container Registry package by
starting the `Validate and Build S3 Image` workflow manually from the Actions
tab. The workflow does not run on push.

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

## Load the audio and deploy

The S3 bucket is private. Sync audio from the public `AI_Nginx` repository:

```bash
export AUDIO_BUCKET_NAME="$(terragrunt --working-dir ../terragrunt \
  output -raw audio_bucket_name)"
export AWS_DEFAULT_REGION="eu-central-1"
ansible-playbook -i localhost, ../ansible/eks-deploy.yml
```

The source repository must contain an `audio/` directory. Ansible puts
`html/audio/` in the private S3 bucket, while the published image provides the
remaining web files. CloudFront reads the bucket through Origin Access Control,
while nginx proxies `/audio/` to CloudFront. The client has no direct S3 access
and the audio files are not copied into the pod.

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
curl -H "Host: weather.local" "http://${LOAD_BALANCER_HOST}/audio/"
```

For browser testing without paid DNS, add the hostname to `/etc/hosts` after
resolving the LoadBalancer address, then open `http://weather.local`.

## Remove everything

Delete application objects first so the Ingress LoadBalancer can be released:

```bash
kubectl delete -f ../kubernetes/ --ignore-not-found
terragrunt --working-dir ../terragrunt destroy --non-interactive
```

Terraform then removes the EKS control plane, Spot node group, private S3
bucket, CloudFront distribution, VPC, subnets, NAT Gateway, route tables,
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
├── ansible/eks-deploy.yml
├── scripts/sync-audio-to-s3.sh
├── terragrunt/terragrunt.hcl
└── terraform-eks/
```

This branch is intentionally separate from the cheap push-triggered EC2
workflow in `main`.
