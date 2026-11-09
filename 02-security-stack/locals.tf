locals {
  prefix = upper(var.project)

  common_tags = {
    Project     = local.prefix
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Repository  = var.repository
    ManagedBy   = "terraform"
    Stack       = "02-security-stack"
  }

  network  = data.terraform_remote_state.network.outputs
  vpc_id   = local.network.vpc_id
  vpc_cidr = local.network.vpc_cidr

  ssm_prefix = "/${var.project}/${var.environment}"
}
