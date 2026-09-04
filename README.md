# ImageTestEnv: local Kubernetes in WSL

This branch is the fourth scenario: one local k3s node and one nginx pod inside
WSL. It does not create AWS resources and does not use a container image from
GHCR or Docker Hub. Terraform and Terragrunt install the local Kubernetes
runtime when possible; Ansible installs the nginx workload and copies the
required `html/` files from `Izanar/AI_Nginx` into the pod.

## Setup

Run these commands inside WSL:

For the complete setup, use the prompted one-command launcher:

```bash
./scripts/deploy.sh
```

It installs k3s through Terraform/Terragrunt and deploys the nginx pod with
Ansible.

```bash
terragrunt --working-dir terragrunt init
terragrunt --working-dir terragrunt apply
ansible-playbook -i localhost, ansible/local-deploy.yml
kubectl get nodes
kubectl get pods -n weather-demo
curl http://127.0.0.1:30080
```

Terraform installs k3s with the requested version and prepares kubeconfig. The
network helper exposes NodePort `30080` on the Windows host when
`powershell.exe` is available. For access from the home LAN, allow inbound TCP
`30080` in Windows Firewall and use the Windows host IP. WSL2 networking and
corporate VPN/firewall policies can still require a local adjustment.

Ansible clones `AI_Nginx`, applies the namespace, one-replica Deployment and
NodePort Service, waits for nginx, then copies `html/` into the running pod.
Because this copy is intentionally performed after pod creation, rerun Ansible
whenever the pod is recreated.

## Remove

```bash
kubectl delete -f kubernetes/ --ignore-not-found
terragrunt --working-dir terragrunt destroy --non-interactive
```

Or use the confirmed one-command cleanup:

```bash
./scripts/destroy.sh
```

## Validation

```bash
terraform -chdir=terraform-local fmt -check -recursive
terraform -chdir=terraform-local init -backend=false -input=false
terraform -chdir=terraform-local validate
ansible-playbook --syntax-check -i localhost, ansible/local-deploy.yml
```

The Docker images used by the AWS Kubernetes branches exist to package the
application for repeatable pod recreation. This local branch deliberately uses
Ansible copy instead, so its one pod always receives the current repository
files.
