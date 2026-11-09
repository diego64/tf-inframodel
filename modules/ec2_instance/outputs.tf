output "instance_ids" {
  description = "Mapa chave -> instance ID."
  value       = { for k, i in aws_instance.this : k => i.id }
}

output "private_ips" {
  description = "Mapa chave -> IP privado."
  value       = { for k, i in aws_instance.this : k => i.private_ip }
}

output "primary_network_interface_ids" {
  description = "Mapa chave -> ENI primária (usada na rota NAT)."
  value       = { for k, i in aws_instance.this : k => i.primary_network_interface_id }
}
