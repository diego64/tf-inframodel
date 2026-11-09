# Deploy do zero

Tempo estimado: 20 minutos (5 de Terraform + 5–10 de bootstrap das VMs).

## Visão das etapas

| Etapa | Stack | Cria | State |
|---|---|---|---|
| 2 | `00-remote-state-stack` | Bucket S3 do state | local (1x) |
| 4 | `01-network-stack` | VPC, subnets, IGW, route tables, flow logs | `faf-lab/01-network-stack.tfstate` |
| 5 | `02-security-stack` | 6 security groups, role/profile IAM, 2 segredos SSM | `faf-lab/02-security-stack.tfstate` |
| 6 | `03-compute-stack` | 16 EC2, rota NAT, EIP | `faf-lab/03-compute-stack.tfstate` |

## Etapa 0 — Pré-requisitos

```bash
terraform version          # >= 1.10
aws --version              # v2
session-manager-plugin     # deve imprimir a mensagem de instalação OK
make --version && jq --version
```

## Etapa 1 — Credenciais e variáveis

```bash
cp .env.example .env
curl -s https://checkip.amazonaws.com      # seu IP público
```

| Onde | Variável | Valor |
|---|---|---|
| `.env` | `AWS_PROFILE` | perfil com permissão de criar VPC/EC2/IAM/SSM/S3 |
| `.env` | `TF_VAR_allowed_ingress_cidrs` | `["<seu-ip>/32"]` |
| `.env` | `TF_VAR_owner`, `TF_VAR_repository` | seus dados |
| `01-network-stack/terraform.tfvars` | `vpc_cidr`, `availability_zone` | padrão ok |
| `03-compute-stack/terraform.tfvars` | `services` | quantidade/tipo das VMs |

```bash
make check-env             # imprime o ARN da identidade em uso
```

## Etapa 2 — Remote state (somente na primeira vez)

```bash
make bootstrap
```

Cria `faf-tfstate-<conta>-us-east-1` com versionamento, SSE, bloqueio público, TLS obrigatório
e `prevent_destroy`. Copie a saída `state_bucket` para `TF_STATE_BUCKET` no `.env`.

## Etapa 3 — Verificar o código

```bash
make check     # fmt-check, validate (todas as stacks), tflint, checkov
```

## Etapa 4 — 01-network-stack

```bash
make init plan STACK=01-network-stack
```

Revise: 1 VPC, 3 subnets, 2 route tables, 1 IGW, SG default sem regras.

```bash
make apply STACK=01-network-stack
```

## Etapa 5 — 02-security-stack

```bash
make init plan STACK=02-security-stack
```

Revise:

- [ ] Ingress `0.0.0.0/0` **só** no que você definiu em `allowed_ingress_cidrs`
- [ ] `FAF_SG_WEB`/`FAF_SG_LAMP` com origem = `FAF_SG_FIREWALL`
- [ ] Nenhuma regra para a porta 22

```bash
make apply STACK=02-security-stack
```

## Etapa 6 — 03-compute-stack

```bash
make init plan STACK=03-compute-stack
# teste barato: make plan STACK=03-compute-stack VAR_FILE=examples/minimal.tfvars
```

Revise:

- [ ] `aws_instance` = 16 (ou 6 no minimal)
- [ ] Tags `Name` no padrão `FAF_<SERVICO>`
- [ ] `aws_route.private_default` apontando para a ENI do gateway

```bash
make apply STACK=03-compute-stack
```

> Atalho: `make deploy-all` executa as etapas 4–6 em sequência e pede confirmação antes de cada apply.

Gere e commite o `.terraform.lock.hcl` de cada stack (fixa as versões dos providers).

## Etapa 7 — Aguardar o bootstrap

```bash
make inventory
make logs NAME=FAF_GATEWAY     # deve terminar com "FAF_GATEWAY pronto"
make logs NAME=FAF_AD_02       # o último a terminar (espera o _01)
```

Ordem típica de conclusão: GATEWAY → FIREWALL → WEB/LAMP/DNS → AD_01 → AD_02.

## Etapa 8 — Validar

Siga [RUNBOOK §2](RUNBOOK.md#2-validação-por-serviço).

## Etapa 9 — Destruir ao final da demonstração

```bash
make destroy-all       # 03 -> 02 -> 01, cada uma pede confirmação
```

Destruir fora de ordem falha: a 01 não remove a VPC enquanto houver ENIs da 03,
e a 02 não remove SGs em uso. O bucket de state permanece (`prevent_destroy`);
ver [RUNBOOK §8](RUNBOOK.md#8-remover-tudo-inclusive-o-state).
