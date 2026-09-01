# =========================================================
# DATA SOURCES
# =========================================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Ubuntu 24.04 LTS
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


# =========================================================
# EC2 SECURITY GROUP
# =========================================================

resource "aws_security_group" "ec2" {
  name        = "nestjs-products-ec2"
  description = "Security group for NestJS EC2"
  vpc_id      = data.aws_vpc.default.id

  # SSH - required for VS Code Remote SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - Docker/Nginx/application
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "nestjs-products-ec2-sg"
    Project = var.project_name
  }
}


# =========================================================
# RDS SECURITY GROUP
# =========================================================

resource "aws_security_group" "rds" {
  name        = "nestjs-products-rds"
  description = "Security group for MySQL RDS"
  vpc_id      = data.aws_vpc.default.id

  # MySQL accessible ONLY from EC2 security group
  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nestjs-products-rds-sg"
  }
}


# =========================================================
# NEW EC2 INSTANCE
# =========================================================

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  associate_public_ip_address = true

  # Your existing AWS key pair
  key_name = aws_key_pair.ec2.key_name
  resource "tls_private_key" "ec2" {
    algorithm = "RSA"
    rsa_bits  = 4096
  }

  resource "aws_key_pair" "ec2" {
    key_name   = "nestjs-products-new-key"
    public_key = tls_private_key.ec2.public_key_openssh
  }

  resource "local_sensitive_file" "ec2_private_key" {
    content         = tls_private_key.ec2.private_key_pem
    filename        = "${path.module}/nestjs-products-new-key.pem"
    file_permission = "0600"
  }

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  # Install Docker and Git when the NEW EC2 is created
  user_data = <<-EOF
              #!/bin/bash

              set -e

              # Update packages
              apt-get update -y

              # Install Docker
              apt-get install -y docker.io

              # Install Git
              apt-get install -y git

              # Start Docker
              systemctl enable docker
              systemctl start docker

              # Allow ubuntu user to run Docker without sudo
              usermod -aG docker ubuntu

              # Create application directory
              mkdir -p /home/ubuntu/nestjs-crud-api

              # Set ownership
              chown -R ubuntu:ubuntu /home/ubuntu/nestjs-crud-api

              # Create deployment marker
              touch /home/ubuntu/docker-ready

              chown ubuntu:ubuntu /home/ubuntu/docker-ready
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


# =========================================================
# EXISTING RDS SUBNET GROUP
# =========================================================

resource "aws_db_subnet_group" "mysql" {
  name = "nestjs-products-db-subnet"

  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name    = "nestjs-products-db-subnet"
    Project = var.project_name
  }
}


# =========================================================
# EXISTING RDS MYSQL
# =========================================================

resource "aws_db_instance" "mysql" {
  identifier = "nestjs-products-mysql"

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

  backup_retention_period = 0

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name    = "nestjs-products-mysql"
    Project = var.project_name
  }
}


# =========================================================
# S3
# =========================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "nestjs-products-bucket"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}