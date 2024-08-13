terraform {
  backend "s3" {
    bucket  = "devcontainer-terraform-template-dev-terraform-state-dev"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    profile = var.aws["profile"]
  }
}
