provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "GitOps Disaster Recovery Simulator"
      Environment = "development"
      ManagedBy   = "Terraform"
    }
  }
}