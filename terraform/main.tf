# ---------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------

# Use the existing AWS default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets belonging to the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ---------------------------------------------------------
# RANDOM ID FOR UNIQUE S3 BUCKET
# ---------------------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
}


# ---------------------------------------------------------
# EC2 SECURITY GROUP
# ---------------------------------------------------------

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2"
  description = "Security group for NestJS EC2"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-ec2-sg"
    Project = var.project_name
  }
}


# ---------------------------------------------------------
# RDS SECURITY GROUP
# ---------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds"
  description = "Security group for NestJS RDS MySQL"
  vpc_id      = data.aws_vpc.default.id

  # Allow MySQL only from EC2
  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}


# ---------------------------------------------------------
# EC2 INSTANCE
# ---------------------------------------------------------

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = data.aws_subnets.default.ids[0]

  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
              #!/bin/bash

              apt-get update -y

              # Install Docker
              apt-get install -y docker.io

              # Install Docker Compose plugin
              apt-get install -y docker-compose-v2

              # Install Git
              apt-get install -y git

              # Start Docker
              systemctl enable docker
              systemctl start docker

              # Allow ubuntu user to run Docker
              usermod -aG docker ubuntu

              # Create application directory
              mkdir -p /home/ubuntu/nestjs-crud-api

              # Give ownership to ubuntu
              chown -R ubuntu:ubuntu /home/ubuntu/nestjs-crud-api
              EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-ec2"
    Project = var.project_name
  }
}


# ---------------------------------------------------------
# RDS SUBNET GROUP
# ---------------------------------------------------------

resource "aws_db_subnet_group" "mysql" {
  name = "${var.project_name}-mysql-subnet-group"

  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name    = "${var.project_name}-mysql-subnet-group"
    Project = var.project_name
  }
}


# ---------------------------------------------------------
# RDS MYSQL
# ---------------------------------------------------------

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 3306

  db_subnet_group_name = aws_db_subnet_group.mysql.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  multi_az = false

  backup_retention_period = 7

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name    = "${var.project_name}-mysql"
    Project = var.project_name
  }
}


# ---------------------------------------------------------
# S3 BUCKET
# ---------------------------------------------------------

resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "${var.project_name}-bucket"
    Project = var.project_name
  }
}


# ---------------------------------------------------------
# S3 BLOCK PUBLIC ACCESS
# ---------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ---------------------------------------------------------
# S3 VERSIONING
# ---------------------------------------------------------

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}