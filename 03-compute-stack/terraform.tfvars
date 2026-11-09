# Valores não sensíveis da 03-compute-stack (versionado).
# Total: 1 + 1 + 2 + 2 + 5 + 5 = 16 máquinas.
# Teste barato (6 VMs): make plan STACK=03-compute-stack VAR_FILE=examples/minimal.tfvars

services = {
  gateway  = { count = 1, instance_type = "t3.micro", tier = "public", ip_offset = 10, volume_size = 10 }
  firewall = { count = 1, instance_type = "t3.micro", tier = "public", ip_offset = 20, volume_size = 10 }
  ad       = { count = 2, instance_type = "t3.small", tier = "core", ip_offset = 10, volume_size = 20 }
  dns      = { count = 2, instance_type = "t3.micro", tier = "core", ip_offset = 20, volume_size = 10 }
  lamp     = { count = 5, instance_type = "t3.small", tier = "app", ip_offset = 10, volume_size = 20 }
  web      = { count = 5, instance_type = "t3.micro", tier = "app", ip_offset = 40, volume_size = 10 }
}

dns_zone   = "faf.internal"
ad_realm   = "ad.faf.internal"
ad_netbios = "FAF"

enable_detailed_monitoring = false
