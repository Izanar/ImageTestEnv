#!/usr/bin/env bash
set -euo pipefail

node_port="${1:-30080}"
if ! command -v powershell.exe >/dev/null; then
  echo "Service is available inside WSL at http://127.0.0.1:${node_port}."
  echo "Configure Windows portproxy and firewall for LAN access when running WSL2."
  exit 0
fi

wsl_ip="$(hostname -I | awk '{print $1}')"
powershell.exe -NoProfile -NonInteractive -Command "netsh interface portproxy delete v4tov4 listenport=${node_port} listenaddress=0.0.0.0; netsh interface portproxy add v4tov4 listenport=${node_port} listenaddress=0.0.0.0 connectport=${node_port} connectaddress=${wsl_ip}"
echo "Port ${node_port} forwards to WSL ${wsl_ip}. Add a Windows inbound firewall rule for TCP ${node_port} for LAN access."