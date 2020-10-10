terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.7.0"
    }
  }

  backend "s3" {
    bucket         = "tf-state-lock-1010"
    key            = "state.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tf-state-lock"
  }
}