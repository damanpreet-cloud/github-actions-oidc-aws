terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

variable "github_org" {
  type    = string
  default = "your-github-username"
}

variable "github_repo" {
  type    = string
  default = "your-infra-repo"
}

module "provider" {
  source = "../../modules/github-oidc-provider"
}

# Read-only role: safe for pull requests, runs `terraform plan`.
module "plan_role" {
  source = "../../modules/github-oidc-role"

  role_name          = "gha-terraform-plan"
  oidc_provider_arn  = module.provider.arn
  github_org         = var.github_org
  github_repo        = var.github_repo
  allow_pull_request = true
  allowed_refs       = ["refs/heads/main"]
  policy_arns        = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

# Write role: only the "production" GitHub Environment (with required
# reviewers) can assume it. Scope the policy to what the pipeline really needs.
module "apply_role" {
  source = "../../modules/github-oidc-role"

  role_name            = "gha-terraform-apply"
  oidc_provider_arn    = module.provider.arn
  github_org           = var.github_org
  github_repo          = var.github_repo
  allowed_environments = ["production"]
  max_session_duration = 3600

  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "ArtifactsBucketOnly"
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = ["arn:aws:s3:::example-artifacts-bucket", "arn:aws:s3:::example-artifacts-bucket/*"]
    }]
  })
}

output "plan_role_arn" {
  value = module.plan_role.role_arn
}

output "apply_role_arn" {
  value = module.apply_role.role_arn
}
