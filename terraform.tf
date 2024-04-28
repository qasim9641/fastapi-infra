terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }

  }

  required_version = ">= 1.7.5, < 1.9.0"

}