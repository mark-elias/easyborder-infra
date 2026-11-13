# looks up my AWS account ID from whatever AWS_PROFILE I'm logged in with, so I don't hardcode it.
data "aws_caller_identity" "current" {}

# My bucket for post images; tacking on the account ID keeps the name globally unique.
resource "aws_s3_bucket" "images" {
  bucket = "easyborder-images-${data.aws_caller_identity.current.account_id}"
}

# Locks the bucket down so nothing in it can ever be made public, even by accident.
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  # Rejects any request that tries to attach a public ACL to the bucket or an object.
  block_public_acls = true
  # Rejects any bucket policy that would grant public access.
  block_public_policy = true
  # Ignores public ACLs that somehow already exist, so they don't actually grant access.
  ignore_public_acls = true
  # Limits access to AWS services and my own account, even if a public policy slips through.
  restrict_public_buckets = true
}

# Lets my frontend's browser talk to S3 directly so it can PUT uploads with presigned URLs from my backend.
resource "aws_s3_bucket_cors_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    # PUT for uploading and GET for reading images back.
    allowed_methods = ["PUT", "GET"]
    # Only my frontend origins (localhost and easyborder.io) are allowed.
    allowed_origins = var.allowed_origins
    # The browser can send any headers, like Content-Type, with the request.
    allowed_headers = ["*"]
    # The browser caches the CORS preflight check for 50 minutes so it isn't repeated on every upload.
    max_age_seconds = 3000
  }
}

# Auto-cleans the bucket so junk files don't pile up and cost me money.
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  # Deletes raw uploads after a day since my resize Lambda will have already turned them into WebP in posts/.
  rule {
    id     = "expire-raw-uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 1
    }
  }

  # Cleans up half-finished uploads across the whole bucket, since S3 still bills for those leftover parts.
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
