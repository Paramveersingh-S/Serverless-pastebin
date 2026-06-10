#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./upload_frontend.sh <environment>"
    exit 1
fi

ENV=$1
cd ../terraform
S3_BUCKET=$(terraform output -raw s3_bucket_name)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id)

cd ../src/frontend
echo "Syncing to s3://$S3_BUCKET"
aws s3 sync . s3://$S3_BUCKET/ --delete

echo "Invalidating CloudFront cache for distribution $CLOUDFRONT_ID"
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"

echo "Done!"
