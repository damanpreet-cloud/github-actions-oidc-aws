variable "role_name" {
  description = "Name of the IAM role GitHub Actions will assume."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider in this account."
  type        = string
}

variable "github_org" {
  description = "GitHub organization or user that owns the repository."
  type        = string

  validation {
    condition     = !can(regex("[*?]", var.github_org))
    error_message = "Wildcards are not allowed in github_org."
  }
}

variable "github_repo" {
  description = "Repository name (without the org). Wildcards are rejected on purpose."
  type        = string

  validation {
    condition     = !can(regex("[*?]", var.github_repo))
    error_message = "Wildcards are not allowed in github_repo. Grant each repository explicitly."
  }
}

variable "allowed_refs" {
  description = "Git refs allowed to assume the role, e.g. [\"refs/heads/main\"]."
  type        = list(string)
  default     = []
}

variable "allowed_environments" {
  description = "GitHub Environments allowed to assume the role, e.g. [\"production\"]."
  type        = list(string)
  default     = []
}

variable "allow_pull_request" {
  description = "Allow workflows triggered by pull requests. Use only for read-only roles."
  type        = bool
  default     = false
}

variable "policy_arns" {
  description = "Managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy document (JSON)."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags for the role."
  type        = map(string)
  default     = {}
}
