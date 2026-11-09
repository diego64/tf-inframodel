# Segredo gerado pelo Terraform e entregue à EC2 via SSM (nunca no user_data).
# Fica no state: bucket criptografado e privado (00-remote-state-stack).
resource "random_password" "lamp_db" {
  length           = 24
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "#%+=_-"
}

resource "aws_ssm_parameter" "lamp_db" {
  name        = "${local.ssm_prefix}/lamp/db_password"
  description = "Senha do usuario de aplicacao MySQL (FAF_LAMP)"
  type        = "SecureString"
  value       = random_password.lamp_db.result

  tags = { Name = "${local.prefix}_SSM_LAMP_DB" }
}
