# Credenciais vêm de AWS_PROFILE / variáveis de ambiente / OIDC — nunca daqui.
provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
