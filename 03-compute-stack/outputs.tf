locals {
  instance_ids = merge(
    module.ec2_gateway.instance_ids,
    module.ec2_firewall.instance_ids,
    module.ec2_ad.instance_ids,
    module.ec2_dns.instance_ids,
    module.ec2_lamp.instance_ids,
    module.ec2_web.instance_ids,
  )
}

output "ubuntu_ami" {
  description = "AMI Ubuntu 22.04 resolvida."
  value = {
    id   = data.aws_ami.ubuntu_2204.id
    name = data.aws_ami.ubuntu_2204.name
  }
}

output "firewall_public_ips" {
  description = "IP(s) público(s) fixo(s) do FAF_FIREWALL."
  value       = { for k, e in aws_eip.firewall : local.instances[k].name => e.public_ip }
}

output "urls" {
  description = "Pontos de acesso publicados pelo FAF_FIREWALL."
  value = {
    for k, e in aws_eip.firewall : local.instances[k].name => {
      site_estatico = "http://${e.public_ip}/"
      site_php      = "http://${e.public_ip}:8080/"
    }
  }
}

output "instances" {
  description = "Inventário: Name -> id, IP privado, hostname, serviço."
  value = {
    for k, v in local.instances : v.name => {
      id         = local.instance_ids[k]
      private_ip = v.private_ip
      hostname   = "${v.hostname}.${var.dns_zone}"
      service    = upper(v.service)
      type       = v.instance_type
    }
  }
}

output "instance_count" {
  description = "Total de máquinas."
  value       = length(local.instances)
}

output "ssm_connect_commands" {
  description = "Shell em cada máquina via SSM Session Manager (sem SSH)."
  value = {
    for k, v in local.instances : v.name => "aws ssm start-session --region ${var.region} --target ${local.instance_ids[k]}"
  }
}

output "directory" {
  description = "Domínio AD e zona DNS interna."
  value = {
    ad_realm   = upper(var.ad_realm)
    ad_netbios = var.ad_netbios
    ad_dcs     = local.ips_by_service["ad"]
    dns_zone   = var.dns_zone
    dns_ips    = local.ips_by_service["dns"]
  }
}
