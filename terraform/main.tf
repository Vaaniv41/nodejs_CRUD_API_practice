data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  id = data.aws_subnets.default.ids[0]
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2"
  description = "Security group for NestJS EC2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NestJS"
    from_port   = var.container_port
    to_port     = var.container_port
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
    Name = "${var.project_name}-ec2-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds"
  description = "Security group for MySQL RDS"
  vpc_id      = data.aws_vpc.default.id

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
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = var.instance_type

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    container_port = var.container_port
  })

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

resource "aws_db_subnet_group" "mysql" {
  name = "${var.project_name}-db-subnet"

  subnet_ids = slice(
    data.aws_subnets.default.ids,
    0,
    min(2, length(data.aws_subnets.default.ids))
  )

  tags = {
    Name = "${var.project_name}-db-subnet"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false
  multi_az            = false

  tags = {
    Name = "${var.project_name}-mysql"
  }
}

resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-s3"
  }
}

data "aws_caller_identity" "current" {}