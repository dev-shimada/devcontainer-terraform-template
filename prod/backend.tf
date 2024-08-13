terraform {
  backend "s3" {
    bucket  = "devcontainer-terraform-template-terraform-state-prod"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    profile = var.aws["profile"]
  }
}
