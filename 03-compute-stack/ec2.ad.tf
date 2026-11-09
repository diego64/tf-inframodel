# -----------------------------------------------------------------------------
# FAF_AD_NN — Samba AD DC (_01 provisiona, demais entram como DC adicional)
# Stateful: não recriar o _01 sem transferir FSMO (RUNBOOK §4).
# -----------------------------------------------------------------------------
module "ec2_ad" {
  source = "../modules/ec2_instance"

  instances                  = local.instances_by_service["ad"]
  ami_id                     = data.aws_ami.ubuntu_2204.id
  subnet_id_by_tier          = local.network.subnet_ids
  security_group_by_service  = local.security.security_group_ids
  instance_profile_name      = local.security.instance_profile_name
  enable_detailed_monitoring = var.enable_detailed_monitoring

  # Sem a rota NAT o apt/snap do bootstrap falha
  depends_on = [aws_route.private_default]
}
