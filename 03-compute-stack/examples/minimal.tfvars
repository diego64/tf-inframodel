# Cenário mínimo (6 máquinas) — validar a stack gastando pouco.
#   make plan STACK=03-compute-stack VAR_FILE=examples/minimal.tfvars
services = {
  gateway  = { count = 1, instance_type = "t3.micro", tier = "public", ip_offset = 10, volume_size = 10 }
  firewall = { count = 1, instance_type = "t3.micro", tier = "public", ip_offset = 20, volume_size = 10 }
  ad       = { count = 1, instance_type = "t3.small", tier = "core", ip_offset = 10, volume_size = 20 }
  dns      = { count = 1, instance_type = "t3.micro", tier = "core", ip_offset = 20, volume_size = 10 }
  lamp     = { count = 1, instance_type = "t3.small", tier = "app", ip_offset = 10, volume_size = 20 }
  web      = { count = 1, instance_type = "t3.micro", tier = "app", ip_offset = 40, volume_size = 10 }
}
