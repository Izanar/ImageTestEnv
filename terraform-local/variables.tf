variable "kubernetes_version" {
  description = "k3s version installed inside WSL"
  type        = string
  default     = "v1.30.6+k3s1"
}

variable "node_port" {
  description = "NodePort used to expose nginx to the local network"
  type        = number
  default     = 30080
}