# TFLint — ref.: https://github.com/terraform-linters/tflint
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Regras específicas da AWS (tipos de instância inválidos, etc.).
# Fixe a versão mais recente disponível em:
# https://github.com/terraform-linters/tflint-ruleset-aws/releases
# plugin "aws" {
#   enabled = true
#   version = "<x.y.z>"
#   source  = "github.com/terraform-linters/tflint-ruleset-aws"
# }

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}
