locals {
  prefix = upper(var.project) # "FAF"

  common_tags = {
    Project     = local.prefix
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Repository  = var.repository
    ManagedBy   = "terraform"
    Stack       = "01-network-stack"
  }

  # Plano de endereçamento determinístico
  subnet_cidrs = {
    public = cidrsubnet(var.vpc_cidr, 8, 0)  # 10.10.0.0/24  -> FAF_GATEWAY, FAF_FIREWALL
    core   = cidrsubnet(var.vpc_cidr, 8, 10) # 10.10.10.0/24 -> FAF_AD, FAF_DNS
    app    = cidrsubnet(var.vpc_cidr, 8, 20) # 10.10.20.0/24 -> FAF_LAMP, FAF_WEB
  }
}
