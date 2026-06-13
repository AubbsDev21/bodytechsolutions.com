#!/usr/bin/env bash
set -eo pipefail

REGION="us-east-1"

BUCKETS=(
  bodytechsolutions-tfstate-iam
  bodytechsolutions-tfstate-cdn
  bodytechsolutions-tfstate-dns
)

TABLES=(
  bodytechsolutions-tfstate-iam-lock
  bodytechsolutions-tfstate-cdn-lock
  bodytechsolutions-tfstate-dns-lock
)

# ── S3 state buckets ──────────────────────────────────────────────

for BUCKET in "${BUCKETS[@]}"; do
  echo "Creating bucket: $BUCKET"

  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION"

  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "$BUCKET" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "Done: $BUCKET"
done

# ── DynamoDB lock tables ──────────────────────────────────────────

for TABLE in "${TABLES[@]}"; do
  echo "Creating table: $TABLE"

  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  echo "Done: $TABLE"
done

echo "Bootstrap complete."
