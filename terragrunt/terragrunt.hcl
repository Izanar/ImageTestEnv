terraform {
  source = "../terraform-eks"
}

inputs = {
  project_name = "image-test-env-eks"
  environment  = "dev"
  aws_region   = "eu-central-1"
  budget_email  = get_env("BUDGET_EMAIL", "")
}