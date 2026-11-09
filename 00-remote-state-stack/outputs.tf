output "state_bucket" {
  description = "Use este valor em TF_STATE_BUCKET no .env."
  value       = aws_s3_bucket.tfstate.bucket
}
