# -----------------------------------------------------------------------------
# FAF_FIREWALL — nftables default-drop + Nginx (80 -> WEB, 8080 -> LAMP)
# IP público fixo (EIP) declarado neste arquivo.
# -----------------------------------------------------------------------------
module "ec2_firewall" {
  source = "../modules/ec2_instance"

  instances                  = local.instances_by_service["firewall"]
  ami_id                     = data.aws_ami.ubuntu_2204.id
  subnet_id_by_tier          = local.network.subnet_ids
  security_group_by_service  = local.security.security_group_ids
  instance_profile_name      = local.security.instance_profile_name
  enable_detailed_monitoring = var.enable_detailed_monitoring
}

# IP público fixo — ponto único de entrada
resource "aws_eip" "firewall" {
  for_each = local.instances_by_service["firewall"]

  domain   = "vpc"
  instance = module.ec2_firewall.instance_ids[each.key]

  tags = { Name = "${each.value.name}_EIP" }
}
