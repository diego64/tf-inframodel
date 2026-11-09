# FAF_SG_WEB — aceita HTTP somente do SG do FAF_FIREWALL (referência de SG, não CIDR)
resource "aws_security_group" "web" {
  name        = "${local.prefix}_SG_WEB"
  description = "Nginx estatico: HTTP apenas do FAF_FIREWALL"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.prefix}_SG_WEB", Service = "WEB" }
}

resource "aws_vpc_security_group_ingress_rule" "web_from_firewall" {
  #checkov:skip=CKV_AWS_260:origem é o SG do FAF_FIREWALL (referenced_security_group_id), não 0.0.0.0/0
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP via FAF_FIREWALL"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.firewall.id

  tags = { Name = "${local.prefix}_SGR_WEB_80_FROM_FIREWALL" }
}
