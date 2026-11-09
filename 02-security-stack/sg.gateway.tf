# FAF_SG_GATEWAY — NAT instance: recebe tudo da VPC e sai para a internet
resource "aws_security_group" "gateway" {
  name        = "${local.prefix}_SG_GATEWAY"
  description = "NAT instance: trafego da VPC encaminhado para a internet"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.prefix}_SG_GATEWAY", Service = "GATEWAY" }
}

resource "aws_vpc_security_group_ingress_rule" "gateway_from_vpc" {
  security_group_id = aws_security_group.gateway.id
  description       = "Trafego da VPC para NAT"
  ip_protocol       = "-1"
  cidr_ipv4         = local.vpc_cidr

  tags = { Name = "${local.prefix}_SGR_GATEWAY_FROM_VPC" }
}

resource "aws_vpc_security_group_egress_rule" "gateway_all" {
  security_group_id = aws_security_group.gateway.id
  description       = "Saida NAT"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "${local.prefix}_SGR_GATEWAY_OUT" }
}
