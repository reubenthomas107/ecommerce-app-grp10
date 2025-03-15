terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Terraform Backend Configuration
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-project-group10"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

