# ADR 0006 — Stacks numeradas e um arquivo por recurso

- **Status:** aceito (substitui o layout root + `modules/network|security_groups|iam_ssm` da v1)
- **Data:** 2026-11-06

## Contexto
Na v1, um único root module gerenciava rede, segurança e as 16 EC2 em um só state.
Qualquer `apply` tinha blast radius total, e o `plan` ficava lento e longo para revisar.

## Decisão
1. **Stacks numeradas**, cada uma com state próprio (`<prefixo>/<stack>.tfstate`):
   `00-remote-state` → `01-network` → `02-security` → `03-compute`.
   O número é a ordem de deploy; o destroy é a ordem inversa.
2. **Um arquivo por recurso**, no padrão `<domínio>.<componente>.tf`
   (`vpc.subnets.tf`, `sg.lamp.tf`, `iam.ec2-role.tf`, `ec2.firewall.tf`).
3. **Contrato por `outputs.tf`** + `terraform_remote_state` (somente leitura) entre stacks.
4. Recursos simples ficam *flat* na stack. Só o `ec2_instance` continua como módulo, porque o
   mesmo hardening é reutilizado por 6 arquivos `ec2.<servico>.tf`.
5. `terraform.tfvars` por stack é versionado (somente valores não sensíveis); identidade e o IP
   pessoal vêm do `.env` (`TF_VAR_*`).

## Alternativas consideradas
| Opção | Por que não |
|---|---|
| Root único (v1) | Blast radius total, state grande |
| Workspaces | Isolam ambientes, não camadas; mesmo código e mesmo state por ambiente |
| Terragrunt | Resolve a duplicação, mas adiciona uma ferramenta à stack de portfólio |
| Terraform Stacks (HCP) | Depende do HCP Terraform |

## Consequências
- (+) Blast radius por camada: mexer em EC2 não toca VPC nem IAM.
- (+) Plans menores e PRs revisáveis; permissões de deploy podem ser separadas por stack.
- (+) Arquivo por recurso: localização imediata (`sg.firewall.tf`) e diffs menores.
- (+) Pode destruir só a 03 (onde está o custo) e manter rede/IAM.
- (−) `variables.shared.tf` duplicado nas três stacks — mudança precisa ser replicada.
- (−) Outputs viram API pública: renomear quebra a stack seguinte.
- (−) Ordem de deploy/destroy é responsabilidade do operador (mitigado por `make deploy-all` / `destroy-all`).
- (−) Serviço novo exige novos arquivos `ec2.<servico>.tf` e `sg.<servico>.tf` (intencional: tudo explícito).

## Migração da v1
O layout de state mudou. Ambiente da v1 já aplicado: `terraform destroy` na v1 e deploy limpo
na v2 (laboratório sem dados persistentes). Migrar via `terraform state mv` entre states é possível,
mas não compensa para um lab.
