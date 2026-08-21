output "ecr_repository_url" { value = aws_ecr_repository.app.repository_url }
output "api_url" { value = "http://${aws_lb.app.dns_name}" }
output "github_actions_role_arn" { value = aws_iam_role.github_actions.arn }
output "ecs_cluster_name" { value = aws_ecs_cluster.this.name }
output "ecs_service_name" { value = aws_ecs_service.app.name }
output "ecs_task_family" { value = aws_ecs_task_definition.app.family }
