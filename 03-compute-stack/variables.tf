# Variáveis específicas da 03-compute-stack (valores em terraform.tfvars)

variable "services" {
  description = <<-EOT
    Catálogo de serviços. Cada chave vira FAF_<CHAVE> (ou FAF_<CHAVE>_NN quando count > 1).
      count         -> quantidade de instâncias
      instance_type -> tipo EC2
      tier          -> subnet: public | core | app
      ip_offset     -> host inicial na subnet (IP fixo = cidrhost(subnet, ip_offset + i))
      volume_size   -> disco raiz em GiB (gp3, criptografado)
  EOT
  type = map(object({
    count         = number
    instance_type = string
    tier          = string
    ip_offset     = number
    volume_size   = number
  }))

  validation {
    condition     = alltrue([for k in ["gateway", "firewall", "ad", "dns", "lamp", "web"] : contains(keys(var.services), k)])
    error_message = "services deve conter: gateway, firewall, ad, dns, lamp, web (um arquivo ec2.<servico>.tf para cada)."
  }

  validation {
    condition     = length(var.services) == 6
    error_message = "Serviço novo exige um novo arquivo ec2.<servico>.tf (ver RUNBOOK §3)."
  }

  validation {
    condition     = var.services["gateway"].count == 1
    error_message = "gateway deve ter count = 1 (único next-hop de saída das subnets privadas)."
  }

  validation {
    condition     = alltrue([for k in ["firewall", "ad", "dns", "lamp", "web"] : var.services[k].count >= 1])
    error_message = "firewall, ad, dns, lamp e web precisam de ao menos 1 instância."
  }

  validation {
    condition     = alltrue([for s in values(var.services) : contains(["public", "core", "app"], s.tier)])
    error_message = "tier deve ser public, core ou app."
  }

  validation {
    condition     = alltrue([for s in values(var.services) : s.ip_offset >= 4 && s.ip_offset + s.count <= 250])
    error_message = "ip_offset deve ser >= 4 (AWS reserva .0-.3) e ip_offset + count <= 250."
  }

  validation {
    condition     = alltrue([for s in values(var.services) : s.volume_size >= 8 && s.volume_size <= 200])
    error_message = "volume_size deve estar entre 8 e 200 GiB."
  }
}

variable "dns_zone" {
  description = "Zona DNS interna servida pelo FAF_DNS (BIND9)."
  type        = string
  default     = "faf.internal"
}

variable "ad_realm" {
  description = "Realm Kerberos / domínio AD (Samba). Subdomínio de dns_zone."
  type        = string
  default     = "ad.faf.internal"
}

variable "ad_netbios" {
  description = "Nome NetBIOS do domínio (até 15 caracteres, maiúsculo)."
  type        = string
  default     = "FAF"

  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{0,14}$", var.ad_netbios))
    error_message = "ad_netbios deve ter até 15 caracteres maiúsculos/números."
  }
}

variable "enable_detailed_monitoring" {
  description = "CloudWatch detailed monitoring (1 min). Custo adicional."
  type        = bool
  default     = false
}
