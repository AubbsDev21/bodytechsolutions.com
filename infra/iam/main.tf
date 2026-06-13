# ── OIDC provider for GitHub Actions ─────────────────────────────────
# Read-only reference — the provider is account-wide infrastructure,
# not owned by this module. Create it once via the AWS console or CLI
# before running this module for the first time.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ── Trust policy — only this repo, main branch or PRs, can assume the role ──
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
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

# ── Permissions policy — scoped ARNs, no bare wildcards ──────────────
data "aws_iam_policy_document" "github_actions_permissions" {

  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:ListBucket",
      "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration",
      "s3:CreateBucket", "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration", "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock",
    ]
    resources = [
      "arn:aws:s3:::bodytechsolutions-tfstate-*",
      "arn:aws:s3:::bodytechsolutions-tfstate-*/*",
    ]
  }

  statement {
    sid    = "TerraformStateLocking"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable",
      "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:TagResource",
    ]
    resources = [
      "arn:aws:dynamodb:*:${var.aws_account_id}:table/bodytechsolutions-tfstate-*-lock",
    ]
  }

  statement {
    sid    = "SiteBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
      "s3:CreateBucket", "s3:PutBucketPolicy", "s3:GetBucketPolicy",
      "s3:PutBucketVersioning", "s3:GetBucketVersioning",
      "s3:PutEncryptionConfiguration", "s3:GetEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock", "s3:GetBucketPublicAccessBlock",
    ]
    resources = [
      "arn:aws:s3:::bodytechsolutions-site",
      "arn:aws:s3:::bodytechsolutions-site/*",
    ]
  }

  # CloudFront access logs bucket
  statement {
    sid    = "LogsBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:ListBucket",
      "s3:CreateBucket", "s3:PutBucketPolicy", "s3:GetBucketPolicy",
      "s3:PutBucketVersioning", "s3:GetBucketVersioning",
      "s3:PutEncryptionConfiguration", "s3:GetEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock", "s3:GetBucketPublicAccessBlock",
      "s3:PutLifecycleConfiguration", "s3:GetLifecycleConfiguration",
      "s3:PutBucketAcl", "s3:GetBucketAcl",
      "s3:PutBucketOwnershipControls", "s3:GetBucketOwnershipControls",
    ]
    resources = [
      "arn:aws:s3:::bodytechsolutions-cf-logs",
      "arn:aws:s3:::bodytechsolutions-cf-logs/*",
    ]
  }

  statement {
    sid    = "Route53Zone"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.route53_zone_id}",
    ]
  }

  statement {
    sid    = "Route53AccountList"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
    ]
    resources = [
      "arn:aws:route53:::change/*",
      "arn:aws:route53:::hostedzone/*",
    ]
  }

  # CloudFront distribution-level actions, scoped to this account
  statement {
    sid    = "CloudFrontDistribution"
    effect = "Allow"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:UpdateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:TagResource",
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations",
    ]
    resources = [
      "arn:aws:cloudfront::${var.aws_account_id}:distribution/*",
    ]
  }

  statement {
    sid    = "CloudFrontOAC"
    effect = "Allow"
    actions = [
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
    ]
    resources = [
      "arn:aws:cloudfront::${var.aws_account_id}:origin-access-control/*",
    ]
  }

  # Response headers policy — security headers
  statement {
    sid    = "CloudFrontResponseHeaders"
    effect = "Allow"
    actions = [
      "cloudfront:CreateResponseHeadersPolicy",
      "cloudfront:GetResponseHeadersPolicy",
      "cloudfront:UpdateResponseHeadersPolicy",
      "cloudfront:DeleteResponseHeadersPolicy",
    ]
    resources = [
      "arn:aws:cloudfront::${var.aws_account_id}:response-headers-policy/*",
    ]
  }

  # ACM — us-east-1 only, certificate ID unknown until RequestCertificate
  statement {
    sid    = "ACMCertificate"
    effect = "Allow"
    actions = [
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:DeleteCertificate",
      "acm:AddTagsToCertificate",
      "acm:ListTagsForCertificate",
    ]
    resources = [
      "arn:aws:acm:us-east-1:${var.aws_account_id}:certificate/*",
    ]
  }

  # WAFv2 — CLOUDFRONT scope ACLs live in us-east-1
  statement {
    sid    = "WAFWebACL"
    effect = "Allow"
    actions = [
      "wafv2:CreateWebACL",
      "wafv2:GetWebACL",
      "wafv2:UpdateWebACL",
      "wafv2:DeleteWebACL",
      "wafv2:TagResource",
    ]
    resources = [
      "arn:aws:wafv2:us-east-1:${var.aws_account_id}:global/webacl/*/*",
    ]
  }

  statement {
    sid    = "WAFList"
    effect = "Allow"
    actions = [
      "wafv2:ListWebACLs",
    ]
    resources = [
      "arn:aws:wafv2:us-east-1:${var.aws_account_id}:global/webacl/*",
    ]
  }

  statement {
    sid    = "STS"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
    ]
    resources = [
      "arn:aws:sts::${var.aws_account_id}:*",
    ]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "github-actions-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}