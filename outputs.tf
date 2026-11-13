output "images_bucket_name" {
  description = "Use as S3_BUCKET_NAME in the backend environment."
  value       = aws_s3_bucket.images.bucket
}