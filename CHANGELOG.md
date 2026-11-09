# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) · Versionamento: [SemVer](https://semver.org/lang/pt-BR/).

## [Unreleased]

## [2.0.0] - 2026-11-06

### Alterado (breaking)
- Layout em stacks numeradas com state próprio: `00-remote-state-stack`, `01-network-stack`,
  `02-security-stack`, `03-compute-stack` ([ADR 0006](docs/adr/0006-stacks.md)).
- Um arquivo por recurso no padrão `<domínio>.<componente>.tf` (`vpc.subnets.tf`, `sg.firewall.tf`, `ec2.lamp.tf`...).
- Módulos `network`, `security_groups` e `iam_ssm` incorporados às stacks; `ec2_instance` mantido.
- Endereços de recurso mudaram (ex.: `module.ec2_web.aws_instance.this["web-03"]`). Ambiente da v1 precisa ser recriado.
- `.env`: `TF_STATE_KEY` substituída por `TF_STATE_PREFIX`.
- `terraform.tfvars` por stack agora é versionado (somente valores não sensíveis).

### Adicionado
- `make deploy-all` / `make destroy-all` com a ordem correta das stacks.
- CI com `validate` em matriz por stack.

### Corrigido
- Security groups com `create_before_destroy` e `name` fixo falhariam ao serem substituídos (nome duplicado). Lifecycle removido.

## [1.0.0] - 2026-11-04

### Adicionado
- VPC `FAF_VPC` com subnets public/core/app em `us-east-1a`.
- 16 instâncias Ubuntu 22.04 LTS: `FAF_GATEWAY`, `FAF_FIREWALL`, `FAF_AD_01..02`, `FAF_DNS_01..02`, `FAF_LAMP_01..05`, `FAF_WEB_01..05`.
- Samba AD DC (`AD.FAF.INTERNAL`) com DC adicional.
- BIND9 primário/secundário para `faf.internal` com forward da zona AD.
- Firewall de borda (nftables + Nginx) e NAT instance.
- Segredos via SSM Parameter Store; acesso via SSM Session Manager.
- Backend S3 com lock nativo.
- CI: fmt, validate, tflint, checkov. Dependabot.
- Documentação: arquitetura, deploy, runbook, troubleshooting, segurança, custos, ADRs.
