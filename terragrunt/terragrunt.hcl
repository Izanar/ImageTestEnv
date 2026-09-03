terraform {
  source = "../terraform"
}

inputs = {
  project_name  = "image-test-env"
  environment   = "dev"
  aws_region    = get_env("AWS_DEFAULT_REGION", "eu-central-1")
  instance_type = "t3.micro"
}