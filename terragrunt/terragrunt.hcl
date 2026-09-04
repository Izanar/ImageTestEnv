terraform {
  source = "../terraform-local"
}

inputs = {
  kubernetes_version = "v1.30.6+k3s1"
  node_port           = 30080
}