output "ecr_repository_url" { value = aws_ecr_repository.app.repository_url }
output "api_url" { value = "http://${aws_lb.app.dns_name}" }
output "github_actions_role_arn" { value = aws_iam_role.github_actions.arn }
output "ec2_instance_id" { value = aws_instance.app.id }
output "ec2_deploy_command" { value = "sudo /usr/local/bin/deploy-nestjs <ecr-image-uri>" }
