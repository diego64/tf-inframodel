# FAF_SG_DNS — BIND9, somente de dentro da VPC
resource "aws_security_group" "dns" {
  name        = "${local.prefix}_SG_DNS"
  description = "BIND9: resolucao interna (53 tcp/udp)"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.prefix}_SG_DNS", Service = "DNS" }
}

resource "aws_vpc_security_group_ingress_rule" "dns_from_vpc" {
  for_each = toset(["tcp", "udp"])

  security_group_id = aws_security_group.dns.id
  description       = "DNS ${upper(each.key)}"
  ip_protocol       = each.key
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = local.vpc_cidr

  tags = { Name = "${local.prefix}_SGR_DNS_${upper(each.key)}_53" }
}
