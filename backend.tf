terraform {
  backend "s3" {
    bucket = "grupo-soat-oficina-mecanica-terraform-state"
    key    = "aws/db-oficina-mecanica/terraform.tfstate"
    region = "us-east-1"
  }
}