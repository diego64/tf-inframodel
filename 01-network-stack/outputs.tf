# Contrato consumido pelas stacks 02 e 03 via terraform_remote_state.
# Renomear uma saída quebra as stacks seguintes.
output "vpc_id" {
  description = "ID da FAF_VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR da VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zone" {
  description = "AZ das subnets."
  value       = var.availability_zone
}

output "subnet_ids" {
  description = "Mapa tier -> subnet ID."
  value = {
    public = aws_subnet.public.id
    core   = aws_subnet.core.id
    app    = aws_subnet.app.id
  }
}

output "subnet_cidrs" {
  description = "Mapa tier -> CIDR (base do plano de IPs fixos)."
  value       = local.subnet_cidrs
}

output "private_route_table_id" {
  description = "Route table privada (recebe a rota default para o FAF_GATEWAY)."
  value       = aws_route_table.private.id
}
