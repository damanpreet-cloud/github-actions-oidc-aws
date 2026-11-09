output "role_arn" {
  description = "ARN to put in role-to-assume in the workflow."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}

output "allowed_subjects" {
  description = "The OIDC subject claims trusted by this role."
  value       = local.allowed_subjects
}
