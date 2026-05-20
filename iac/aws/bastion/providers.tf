terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}
