# Egress comum a todos os SGs exceto FAF_SG_GATEWAY (que é livre, ver sg.gateway.tf):
# VPC inteira + 80/443 para internet (apt, snap, endpoints SSM).
# NTP usa 169.254.169.123 (link-local, não passa pelo SG).
locals {
  egress_targets = {
    firewall = aws_security_group.firewall.id
    ad       = aws_security_group.ad.id
    dns      = aws_security_group.dns.id
    lamp     = aws_security_group.lamp.id
    web      = aws_security_group.web.id
  }

  egress_profile = {
    vpc   = { proto = "-1", from = null, to = null, desc = "Trafego interno VPC" }
    http  = { proto = "tcp", from = 80, to = 80, desc = "apt (HTTP)" }
    https = { proto = "tcp", from = 443, to = 443, desc = "apt/snap/SSM (HTTPS)" }
  }

  egress_rules = merge([
    for svc, sg_id in local.egress_targets : {
      for name, r in local.egress_profile : "${svc}-${name}" => merge(r, { svc = svc, sg_id = sg_id, rule = name })
    }
  ]...)
}

resource "aws_vpc_security_group_egress_rule" "common" {
  for_each = local.egress_rules

  security_group_id = each.value.sg_id
  description       = each.value.desc
  ip_protocol       = each.value.proto
  from_port         = each.value.from
  to_port           = each.value.to
  cidr_ipv4         = each.value.rule == "vpc" ? local.vpc_cidr : "0.0.0.0/0"

  tags = { Name = "${local.prefix}_SGR_${upper(each.value.svc)}_OUT_${upper(each.value.rule)}" }
}
