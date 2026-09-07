terraform {
  backend "s3" {
    bucket = "grupo-soat-oficina-mecanica-terraform-state"
    key    = "aws/terraform.tfstate"
    region = "us-east-1"
  }
}