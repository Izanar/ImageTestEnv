# This file is a Terragrunt wrapper around the Terraform module in ../terraform.
# It does not replace Terraform or create a second infrastructure system.
# It is used to standardize environment defaults and pass values into the same module.

terraform {
  source = "../terraform"
}

inputs = {
  aws_region        = "eu-central-1"
  environment       = "dev"
  project_name      = "image-test-env"
  instance_type     = "t3.micro"
  ssh_cidr_blocks   = ["0.0.0.0/0"]
  http_cidr_blocks  = ["0.0.0.0/0"]
  https_cidr_blocks = ["0.0.0.0/0"]
}

# For a demo this is intentional, but for a real environment you should tighten
# these CIDR lists to your own office / VPN / runner IP ranges.
