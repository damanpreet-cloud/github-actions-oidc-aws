locals {
  repo_prefix = "repo:${var.github_org}/${var.github_repo}"

  allowed_subjects = concat(
    [for ref in var.allowed_refs : "${local.repo_prefix}:ref:${ref}"],
    [for env in var.allowed_environments : "${local.repo_prefix}:environment:${env}"],
    var.allow_pull_request ? ["${local.repo_prefix}:pull_request"] : [],
  )
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # Token must be issued for AWS STS.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Token must come from this exact repository and ref/environment/PR.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags

  lifecycle {
    precondition {
      condition     = length(local.allowed_subjects) > 0
      error_message = "Set at least one of allowed_refs, allowed_environments, or allow_pull_request."
    }
  }
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count  = var.inline_policy_json == null ? 0 : 1
  name   = "${var.role_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
