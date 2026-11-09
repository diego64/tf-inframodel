# Variáveis específicas da 01-network-stack (valores em terraform.tfvars)
variable "availability_zone" {
  description = "AZ única do laboratório (ver docs/adr/0003-single-az.md)."
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "CIDR da VPC. As subnets são derivadas com cidrsubnet()."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "vpc_cidr deve ser IPv4 válido com prefixo /20 ou maior (ex.: 10.10.0.0/16)."
  }
}

variable "enable_flow_logs" {
  description = "Ativa VPC Flow Logs no CloudWatch (custo adicional)."
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Retenção dos Flow Logs (dias)."
  type        = number
  default     = 14
}
