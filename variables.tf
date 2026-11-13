variable "aws_region" {
  description = "AWS region for all resources (matches existing EC2 and RDS)."
  type        = string
  default     = "us-east-1"
}

variable "allowed_origins" {
  description = "Frontend origins allowed to upload directly to S3 via presigned URLs."
  type        = list(string)
  default = [
    "http://localhost:3000",
    "https://easyborder.io",
  ]
}