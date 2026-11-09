# FAF_SG_FIREWALL — único ponto de entrada público
locals {
  firewall_public_ports = {
    "80"   = "HTTP site estatico (FAF_WEB)"
    "8080" = "HTTP site PHP (FAF_LAMP)"
  }

  firewall_ingress = merge([
    for cidr in var.allowed_ingress_cidrs : {
      for port, desc in local.firewall_public_ports : "${port}-${cidr}" => { port = tonumber(port), cidr = cidr, desc = desc }
    }
  ]...)
}

resource "aws_security_group" "firewall" {
  name        = "${local.prefix}_SG_FIREWALL"
  description = "Borda: unico ponto de entrada publico (80 e 8080)"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.prefix}_SG_FIREWALL", Service = "FIREWALL" }
}

resource "aws_vpc_security_group_ingress_rule" "firewall_public" {
  for_each = local.firewall_ingress

  security_group_id = aws_security_group.firewall.id
  description       = each.value.desc
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr

  tags = { Name = "${local.prefix}_SGR_FIREWALL_${each.value.port}" }
}
