# ── CloudFront access logs bucket ────────────────────────────────────
#checkov:skip=CKV_AWS_18: Logging this bucket to itself is circular; CloudFront access logs are the primary access record
#checkov:skip=CKV_AWS_144: Cross-region replication is disproportionate for ephemeral log data
#checkov:skip=CKV_AWS_145: AES256 is sufficient; KMS requires key policy access for the CloudFront log delivery service
#checkov:skip=CKV2_AWS_62: No event notification consumer for log data
resource "aws_s3_bucket" "logs" {
  bucket = "bodytechsolutions-cf-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# BucketOwnerPreferred is required for the log-delivery-write ACL below.
# BucketOwnerEnforced disables ACLs entirely, which breaks CloudFront log delivery.
#checkov:skip=CKV2_AWS_65: BucketOwnerPreferred is intentional; BucketOwnerEnforced breaks CloudFront log delivery
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Grants CloudFront's log delivery service write access to this bucket.
# The LogDelivery group is not AllUsers or AuthenticatedUsers, so this
# is not a public ACL and is not affected by block_public_acls.
resource "aws_s3_bucket_acl" "logs" {
  depends_on = [
    aws_s3_bucket_ownership_controls.logs,
    aws_s3_bucket_public_access_block.logs,
  ]
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

# All access to this bucket must use HTTPS. CloudFront log delivery and
# the deploy role both use HTTPS, so this does not affect either.
resource "aws_s3_bucket_policy" "logs" {
  depends_on = [aws_s3_bucket_public_access_block.logs]
  bucket     = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = { AWS = "*" }
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.logs.arn, "${aws_s3_bucket.logs.arn}/*"]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Transition to cheaper storage after 30 days, expire after 90
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}
