# ── OIDC provider for GitHub Actions ─────────────────────────────────
# Only create this once per AWS account. If it already exists, import
# it instead of creating a duplicate.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# ── Trust policy — only this repo, only main branch, can assume the role ──
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-execution-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# ── Permissions policy ────────────────────────────────────────────────
data "aws_iam_policy_document" "github_actions_permissions" {
  # Terraform state — dns, cdn, iam state buckets
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::bodytechsolutions-tfstate-*",
      "arn:aws:s3:::bodytechsolutions-tfstate-*/*",
    ]
  }

  # State locking
  statement {
    sid    = "TerraformStateLocking"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:aws:dynamodb:*:${var.aws_account_id}:table/bodytechsolutions-tfstate-*-lock",
    ]
  }

  # Route 53 — manage DNS records
  statement {
    sid    = "Route53Access"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
    ]
    resources = ["*"]
  }

  # S3 site bucket — content sync
  statement {
    sid    = "SiteBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::bodytechsolutions-site",
      "arn:aws:s3:::bodytechsolutions-site/*",
    ]
  }

  # S3 bucket management — for cdn layer to create/configure the bucket
  statement {
    sid    = "SiteBucketManagement"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:PutBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPolicy",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
    ]
    resources = [
      "arn:aws:s3:::bodytechsolutions-site",
    ]
  }

  # CloudFront — manage distribution and invalidations
  statement {
    sid    = "CloudFrontAccess"
    effect = "Allow"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:UpdateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:TagResource",
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
    ]
    resources = ["*"]
  }

  # ACM — certificate management, us-east-1 for CloudFront
  statement {
    sid    = "ACMAccess"
    effect = "Allow"
    actions = [
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:DeleteCertificate",
      "acm:AddTagsToCertificate",
      "acm:ListTagsForCertificate",
    ]
    resources = ["*"]
  }

  # WAF — web ACL management, CLOUDFRONT scope is global/us-east-1
  statement {
    sid    = "WAFAccess"
    effect = "Allow"
    actions = [
      "wafv2:CreateWebACL",
      "wafv2:GetWebACL",
      "wafv2:UpdateWebACL",
      "wafv2:DeleteWebACL",
      "wafv2:TagResource",
      "wafv2:ListWebACLs",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "github-actions-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}