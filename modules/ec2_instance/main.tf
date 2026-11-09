# -----------------------------------------------------------------------------
# Módulo ec2_instance: N instâncias Ubuntu a partir de um mapa (for_each)
# Hardening aplicado a todas:
#  - IMDSv2 obrigatório (http_tokens = required)
#  - EBS raiz gp3 criptografado
#  - Sem key pair / sem SSH: acesso via SSM Session Manager
#  - IP privado fixo (plano de IPs determinístico)
# -----------------------------------------------------------------------------

resource "aws_instance" "this" {
  for_each = var.instances

  ami                         = var.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = var.subnet_id_by_tier[each.value.tier]
  private_ip                  = each.value.private_ip
  vpc_security_group_ids      = [var.security_group_by_service[each.value.service]]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = each.value.public
  source_dest_check           = each.value.source_dest_check
  monitoring                  = var.enable_detailed_monitoring
  ebs_optimized               = true
  user_data                   = each.value.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = each.value.volume_size
    encrypted             = true
    delete_on_termination = true

    tags = { Name = "${each.value.name}_ROOT" }
  }

  credit_specification {
    cpu_credits = "standard" # evita cobrança surpresa de créditos "unlimited" em t3
  }

  tags = {
    Name     = each.value.name
    Service  = upper(each.value.service)
    Hostname = each.value.hostname
    Tier     = each.value.tier
  }

  lifecycle {
    # ami:       nova AMI da Canonical não deve recriar as 16 máquinas a cada plan.
    # user_data: o cloud-init roda só no primeiro boot; mudanças de script são
    #            aplicadas com `terraform apply -replace=...` (ver docs/RUNBOOK.md).
    ignore_changes = [ami, user_data]
  }
}
