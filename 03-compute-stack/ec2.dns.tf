# -----------------------------------------------------------------------------
# FAF_DNS_NN — BIND9 (_01 primário, demais secundários via AXFR)
# Zona gerada a partir do inventário (locals.tf).
# -----------------------------------------------------------------------------
module "ec2_dns" {
  source = "../modules/ec2_instance"

  instances                  = local.instances_by_service["dns"]
  ami_id                     = data.aws_ami.ubuntu_2204.id
  subnet_id_by_tier          = local.network.subnet_ids
  security_group_by_service  = local.security.security_group_ids
  instance_profile_name      = local.security.instance_profile_name
  enable_detailed_monitoring = var.enable_detailed_monitoring

  # Sem a rota NAT o apt/snap do bootstrap falha
  depends_on = [aws_route.private_default]
}
