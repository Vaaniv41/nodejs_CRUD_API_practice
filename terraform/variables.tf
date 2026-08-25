variable "aws_region" {
  description = "AWS region for the deployment."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix for AWS resources."
  type        = string
  default     = "nestjs-products"
}

variable "github_repository" {
  description = "GitHub repository in owner/repository format."
  type        = string
}

variable "app_port" {
  type    = number
  default = 5000
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}
