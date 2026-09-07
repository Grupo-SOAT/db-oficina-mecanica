data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = var.infra_state_bucket
    key    = var.infra_state_key
    region = var.aws_region
  }
}


resource "aws_db_subnet_group" "rds" {
  name = "oficina-mecanica-rds"

  subnet_ids = data.terraform_remote_state.infra.outputs.subnet_ids

  tags = {
    Name    = "oficina-mecanica-rds"
    Project = "oficina-mecanica"
  }
}


resource "aws_security_group" "rds" {
  name        = "oficina-mecanica-rds"
  description = "Security group for Oficina Mecanica PostgreSQL"

  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id

  ingress {
    description = "PostgreSQL from VPC"

    from_port = 5432
    to_port   = 5432

    protocol = "tcp"

    cidr_blocks = [
      data.terraform_remote_state.infra.outputs.vpc_cidr_block
    ]
  }

  egress {
    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "oficina-mecanica-rds"
    Project = "oficina-mecanica"
  }
}


resource "aws_db_instance" "postgres" {
  identifier = var.db_identifier

  engine         = "postgres"
  engine_version = "16"

  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = var.db_port

  db_subnet_group_name = aws_db_subnet_group.rds.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  multi_az = false

  backup_retention_period = 1

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name    = var.db_identifier
    Project = "oficina-mecanica"
  }
}