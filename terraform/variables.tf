variable "project_name" {
  description = "Base project name"
  type        = string
  default     = "image-test-env"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_cidr_blocks" {
  description = "CIDR ranges allowed to reach SSH on the EC2 instance"
  type        = list(string)
  default     = []
}

variable "http_cidr_blocks" {
  description = "CIDR ranges allowed to reach HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "CIDR ranges allowed to reach HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "budget_email" {
  description = "Optional email address for the monthly AWS Budget alert"
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Optional AWS Budget threshold in USD"
  type        = number
  default     = 5
}
