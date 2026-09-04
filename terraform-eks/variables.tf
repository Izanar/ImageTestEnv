variable "project_name" {
  description = "Base project name"
  type        = string
  default     = "image-test-env-eks"
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

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
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
