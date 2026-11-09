# Leitura das saídas das stacks anteriores (somente leitura).
# Ref.: https://developer.hashicorp.com/terraform/language/state/remote-state-data
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.state_key_prefix}/01-network-stack.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.state_key_prefix}/02-security-stack.tfstate"
    region = var.region
  }
}
