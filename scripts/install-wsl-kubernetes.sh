#!/usr/bin/env bash
set -euo pipefail

version="${1:?k3s version is required}"
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }

if ! command -v k3s >/dev/null; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$version" sh -
fi

sudo k3s kubectl version --client >/dev/null
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
mkdir -p "$HOME/.kube"
cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
sed -i "s/127.0.0.1/localhost/" "$HOME/.kube/config"
kubectl get nodes --no-headers | grep -q ' Ready '