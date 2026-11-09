# -----------------------------------------------------------------------------
# Bootstrap (cloud-init): user_data = templates/common.sh + templates/<servico>.sh
# -----------------------------------------------------------------------------
locals {
  template_vars = {
    project          = var.project
    environment      = var.environment
    region           = var.region
    vpc_cidr         = local.network.vpc_cidr
    vpc_dns_resolver = local.vpc_dns_resolver
    dns_zone         = var.dns_zone
    ad_realm         = var.ad_realm
    ad_netbios       = var.ad_netbios
    ad_ips           = local.ips_by_service["ad"]
    dns_ips          = local.ips_by_service["dns"]
    web_ips          = local.ips_by_service["web"]
    lamp_ips         = local.ips_by_service["lamp"]
    dns_records      = local.dns_records
    dns_serial       = local.dns_serial
    ssm_ad_admin     = local.security.ssm_parameters.ad_admin_password
    ssm_lamp_db      = local.security.ssm_parameters.lamp_db_password
  }

  user_data = {
    for k, v in local.instances : k => join("\n", [
      templatefile("${path.module}/templates/common.sh.tftpl", merge(local.template_vars, v)),
      templatefile("${path.module}/templates/${v.service}.sh.tftpl", merge(local.template_vars, v)),
    ])
  }
}
