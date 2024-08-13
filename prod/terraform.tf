terraform {
  required_version = "1.9.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.62"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}
