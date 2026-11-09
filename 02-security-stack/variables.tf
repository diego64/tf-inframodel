# Variáveis específicas da 02-security-stack
variable "allowed_ingress_cidrs" {
  description = "CIDRs autorizados no FAF_FIREWALL (80 e 8080). Use seu IP/32 (definido no .env)."
  type        = list(string)

  validation {
    condition     = length(var.allowed_ingress_cidrs) > 0 && alltrue([for c in var.allowed_ingress_cidrs : can(cidrnetmask(c))])
    error_message = "Informe ao menos um CIDR IPv4 válido (ex.: [\"203.0.113.10/32\"])."
  }
}
