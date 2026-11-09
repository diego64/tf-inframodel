# -----------------------------------------------------------------------------
# FAF_GATEWAY — NAT instance (saída das subnets privadas)
# Borda: sobe primeiro; as privadas dependem da rota abaixo.
# -----------------------------------------------------------------------------
module "ec2_gateway" {
  source = "../modules/ec2_instance"

  instances                  = local.instances_by_service["gateway"]
  ami_id                     = data.aws_ami.ubuntu_2204.id
  subnet_id_by_tier          = local.network.subnet_ids
  security_group_by_service  = local.security.security_group_ids
  instance_profile_name      = local.security.instance_profile_name
  enable_detailed_monitoring = var.enable_detailed_monitoring
}

# Saída para a internet das subnets privadas via ENI do FAF_GATEWAY
resource "aws_route" "private_default" {
  route_table_id         = local.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.ec2_gateway.primary_network_interface_ids["gateway-01"]
}
