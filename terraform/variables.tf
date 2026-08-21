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

variable "app_image" {
  description = "Initial image; CI/CD deploys later images."
  type        = string
  default     = "public.ecr.aws/docker/library/node:20-alpine"
}

variable "github_repository" {
  description = "GitHub repository in owner/repository format."
  type        = string
}

variable "container_port" {
  type    = number
  default = 5000
}
