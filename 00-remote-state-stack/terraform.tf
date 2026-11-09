# -----------------------------------------------------------------------------
# 00-remote-state-stack — bucket S3 do remote state das demais stacks.
# Usa state LOCAL de propósito (problema do ovo e da galinha). Rode uma vez.
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
