variable "project" {
  description = "Prefixo do projeto (minúsculo)."
  type        = string
  default     = "faf"
}

variable "region" {
  description = "Região do bucket de state."
  type        = string
  default     = "us-east-1"
}
