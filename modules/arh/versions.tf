## requirements

terraform {
  # Terraform test is an experimental features introduced in Terraform CLI v0.15.0.
  # So, you'll need to upgrade to v0.15.0 or later to use terraform test.
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.62"
    }
  }
}
