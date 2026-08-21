# AWS deployment and CI/CD

Terraform in `terraform/` provisions an ECR repository, ECS Fargate service, Application Load Balancer, MySQL RDS instance, CloudWatch logs, and a GitHub OIDC role. The RDS-generated password is injected into the ECS task from Secrets Manager; it is not stored in the repository.

## One-time infrastructure setup

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and replace `github_repository` with `owner/repository`.
2. Authenticate Terraform with an AWS identity that may create the listed resources, then run:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply
```

3. In GitHub repository settings, add these Actions secrets from the Terraform outputs:

| Secret | Value |
| --- | --- |
| `AWS_DEPLOY_ROLE_ARN` | `github_actions_role_arn` |
| `AWS_REGION` | your Terraform region, for example `ap-south-1` |
| `ECR_REPOSITORY` | last component of `ecr_repository_url`, normally `nestjs-products` |
| `ECS_CLUSTER` | `ecs_cluster_name` |
| `ECS_SERVICE` | `ecs_service_name` |
| `ECS_TASK_FAMILY` | `ecs_task_family` |

The first Terraform apply provisions the service using the default image. Push to `main` after setting the secrets to publish the real API image and replace that task definition. The public URL is `api_url`.

## Pipeline

Pull requests run `npm ci`, build the NestJS application, and run tests. A push to `main` obtains short-lived AWS credentials through GitHub OIDC, builds an image tagged with the commit SHA, pushes it to ECR, then registers and deploys the new ECS task definition.

> This is a billable AWS environment (especially RDS and the ALB). Remove it with `terraform -chdir=terraform destroy` when it is no longer needed.
