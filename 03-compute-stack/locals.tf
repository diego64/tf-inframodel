# -----------------------------------------------------------------------------
# Nomenclatura, plano de IPs e inventário das máquinas
# -----------------------------------------------------------------------------
locals {
  prefix = upper(var.project) # "FAF"

  common_tags = {
    Project     = local.prefix
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Repository  = var.repository
    ManagedBy   = "terraform"
    Stack       = "03-compute-stack"
  }

  network  = data.terraform_remote_state.network.outputs
  security = data.terraform_remote_state.security.outputs

  # AmazonProvidedDNS = base da VPC + 2
  vpc_dns_resolver = cidrhost(local.network.vpc_cidr, 2)

  # Uma entrada por máquina. Chave estável "<servico>-NN".
  #   Tag Name : FAF_<SERVICO> (count == 1) | FAF_<SERVICO>_NN (count > 1)
  #   Hostname : faf-<servico>-NN  (RFC 1123 não aceita "_")
  instances = merge([
    for svc, cfg in var.services : {
      for i in range(cfg.count) : format("%s-%02d", svc, i + 1) => {
        service           = svc
        index             = i + 1
        name              = cfg.count > 1 ? format("%s_%s_%02d", local.prefix, upper(svc), i + 1) : format("%s_%s", local.prefix, upper(svc))
        hostname          = format("%s-%s-%02d", var.project, svc, i + 1)
        instance_type     = cfg.instance_type
        tier              = cfg.tier
        private_ip        = cidrhost(local.network.subnet_cidrs[cfg.tier], cfg.ip_offset + i)
        volume_size       = cfg.volume_size
        public            = cfg.tier == "public"
        source_dest_check = svc != "gateway" # NAT precisa encaminhar pacotes de terceiros
      }
    }
  ]...)

  ips_by_service = {
    for svc in keys(var.services) : svc => [
      for k in sort([for k, v in local.instances : k if v.service == svc]) : local.instances[k].private_ip
    ]
  }

  dns_records = [
    for k in sort(keys(local.instances)) : {
      host = local.instances[k].hostname
      ip   = local.instances[k].private_ip
    }
  ]

  # Serial SOA determinístico: muda apenas quando os registros mudam
  dns_serial = parseint(substr(md5(jsonencode(local.dns_records)), 0, 7), 16)

  # Entrada do módulo ec2_instance, agrupada por serviço (consumida em ec2.<servico>.tf)
  instances_by_service = {
    for svc in keys(var.services) : svc => {
      for k, v in local.instances : k => merge(v, { user_data = local.user_data[k] }) if v.service == svc
    }
  }
}
