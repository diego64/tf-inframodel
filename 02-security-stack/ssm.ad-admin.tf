# Segredo gerado pelo Terraform e entregue à EC2 via SSM (nunca no user_data).
# Fica no state: bucket criptografado e privado (00-remote-state-stack).
resource "random_password" "ad_admin" {
  length           = 24
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "#%+=_-"
}

resource "aws_ssm_parameter" "ad_admin" {
  name        = "${local.ssm_prefix}/ad/admin_password"
  description = "Senha do Administrator do dominio AD (FAF_AD)"
  type        = "SecureString"
  value       = random_password.ad_admin.result

  tags = { Name = "${local.prefix}_SSM_AD_ADMIN" }
}
