terraform {
  backend "s3" {
    key    = "aws/db-oficina-mecanica/terraform.tfstate"
    region = "us-east-1"
  }
}