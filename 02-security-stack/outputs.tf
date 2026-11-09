# Contrato consumido pela 03-compute-stack via terraform_remote_state.
output "security_group_ids" {
  description = "Mapa serviço -> security group ID."
  value = {
    gateway  = aws_security_group.gateway.id
    firewall = aws_security_group.firewall.id
    ad       = aws_security_group.ad.id
    dns      = aws_security_group.dns.id
    lamp     = aws_security_group.lamp.id
    web      = aws_security_group.web.id
  }
}

output "instance_profile_name" {
  description = "Instance profile das EC2."
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_role_arn" {
  description = "ARN da role das EC2."
  value       = aws_iam_role.ec2.arn
}

output "ssm_parameters" {
  description = "Caminhos dos segredos no SSM (valores não expostos)."
  value = {
    ad_admin_password = aws_ssm_parameter.ad_admin.name
    lamp_db_password  = aws_ssm_parameter.lamp_db.name
  }
}
