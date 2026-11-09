# -----------------------------------------------------------------------------
# Variáveis compartilhadas entre as stacks 01-03 (mesmo conteúdo nas três).
# Valores vêm do .env (TF_VAR_*). Ver docs/adr/0006-stacks.md.
# -----------------------------------------------------------------------------
variable "project" {
  description = "Prefixo do projeto. Vira FAF_<SERVICO> (maiúsculo) nas tags Name."
  type        = string
  default     = "faf"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.project))
    error_message = "project deve ter 2-10 caracteres minúsculos, começando por letra."
  }
}

variable "environment" {
  description = "Ambiente (lab, dev, staging, prod)."
  type        = string
  default     = "lab"

  validation {
    condition     = contains(["lab", "dev", "staging", "prod"], var.environment)
    error_message = "environment deve ser lab, dev, staging ou prod."
  }
}

variable "region" {
  description = "Região AWS."
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Tag Owner."
  type        = string
  default     = "devops"
}

variable "cost_center" {
  description = "Tag CostCenter."
  type        = string
  default     = "portfolio"
}

variable "repository" {
  description = "Tag Repository."
  type        = string
  default     = "https://github.com/<usuario>/terraform-aws-faf-lab"
}

# ---------- Remote state (stacks anteriores) ----------
variable "state_bucket" {
  description = "Bucket do remote state (TF_STATE_BUCKET, injetado pelo Makefile)."
  type        = string
}

variable "state_key_prefix" {
  description = "Prefixo das chaves de state (TF_STATE_PREFIX)."
  type        = string
  default     = "faf-lab"
}
