# FAF_SG_AD — Samba AD DC, somente de dentro da VPC
# Ref.: https://wiki.samba.org/index.php/Samba_AD_DC_Port_Usage
locals {
  ad_ports = {
    "tcp-53"    = { proto = "tcp", from = 53, to = 53, desc = "DNS" }
    "tcp-88"    = { proto = "tcp", from = 88, to = 88, desc = "Kerberos" }
    "tcp-135"   = { proto = "tcp", from = 135, to = 135, desc = "RPC endpoint mapper" }
    "tcp-139"   = { proto = "tcp", from = 139, to = 139, desc = "NetBIOS session" }
    "tcp-389"   = { proto = "tcp", from = 389, to = 389, desc = "LDAP" }
    "tcp-445"   = { proto = "tcp", from = 445, to = 445, desc = "SMB" }
    "tcp-464"   = { proto = "tcp", from = 464, to = 464, desc = "Kerberos kpasswd" }
    "tcp-636"   = { proto = "tcp", from = 636, to = 636, desc = "LDAPS" }
    "tcp-3268"  = { proto = "tcp", from = 3268, to = 3269, desc = "Global Catalog" }
    "tcp-49152" = { proto = "tcp", from = 49152, to = 65535, desc = "RPC dinamico" }
    "udp-53"    = { proto = "udp", from = 53, to = 53, desc = "DNS" }
    "udp-88"    = { proto = "udp", from = 88, to = 88, desc = "Kerberos" }
    "udp-123"   = { proto = "udp", from = 123, to = 123, desc = "NTP" }
    "udp-137"   = { proto = "udp", from = 137, to = 138, desc = "NetBIOS name/datagram" }
    "udp-389"   = { proto = "udp", from = 389, to = 389, desc = "CLDAP" }
    "udp-464"   = { proto = "udp", from = 464, to = 464, desc = "Kerberos kpasswd" }
  }
}

resource "aws_security_group" "ad" {
  name        = "${local.prefix}_SG_AD"
  description = "Samba AD DC: Kerberos, LDAP, SMB, RPC, DNS do dominio"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.prefix}_SG_AD", Service = "AD" }
}

resource "aws_vpc_security_group_ingress_rule" "ad_from_vpc" {
  for_each = local.ad_ports

  security_group_id = aws_security_group.ad.id
  description       = each.value.desc
  ip_protocol       = each.value.proto
  from_port         = each.value.from
  to_port           = each.value.to
  cidr_ipv4         = local.vpc_cidr

  tags = { Name = "${local.prefix}_SGR_AD_${upper(replace(each.key, "-", "_"))}" }
}
