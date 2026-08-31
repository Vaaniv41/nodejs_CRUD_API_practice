variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "nestjs-products"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "nestjs-products-key"
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "products_db"
}

variable "db_username" {
  description = "RDS database username"
  type        = string
  default     = "products_user"
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}