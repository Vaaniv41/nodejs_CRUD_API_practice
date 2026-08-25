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

variable "container_port" {
  description = "Port on which NestJS runs"
  type        = number
  default     = 3000
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "products_db"
}

variable "db_username" {
  description = "MySQL username"
  type        = string
  default     = "products_user"
}

variable "db_password" {
  description = "MySQL password"
  type        = string
  sensitive   = true
}