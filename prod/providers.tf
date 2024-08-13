provider "aws" {
  region  = var.aws["region"]
  profile = var.aws["profile"]
  default_tags {
    tags = {
      "Terraform" = "true"
      "Service"   = "devcontainer-terraform-template"
    }
  }
}
