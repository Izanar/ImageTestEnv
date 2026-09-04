output "service_url_inside_wsl" {
  description = "Local URL for the nginx NodePort"
  value       = "http://127.0.0.1:${var.node_port}"
}

output "network_note" {
  description = "How to expose the service beyond WSL"
  value       = "Run scripts/configure-wsl-network.sh ${var.node_port} and allow TCP ${var.node_port} in Windows Firewall if required."
}