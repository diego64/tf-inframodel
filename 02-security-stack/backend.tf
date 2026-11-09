# Backend S3 com configuração parcial: bucket/key/region vêm do `make init`.
# key = <TF_STATE_PREFIX>/02-security-stack.tfstate  (um state por stack = blast radius isolado)
# Ref.: https://developer.hashicorp.com/terraform/language/backend/s3
terraform {
  backend "s3" {}
}
