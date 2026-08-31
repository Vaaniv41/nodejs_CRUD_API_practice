output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS"
  value       = aws_instance.app.public_dns
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.mysql.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.mysql.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.mysql.username
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.app.bucket
}

output "ssh_command" {
  description = "SSH command for EC2"
  value       = "ssh -i <path-to-nestjs-products-key.pem> ubuntu@${aws_instance.app.public_ip}"
}