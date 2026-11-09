# Módulo `ec2_instance`

Usado por cada `03-compute-stack/ec2.<servico>.tf` (um bloco `module "ec2_<servico>"` por serviço).

Cria N instâncias Ubuntu 22.04 a partir de um mapa (`for_each`), com chave estável
(`web-03`) para que escalar um serviço não renomeie/recrie as máquinas existentes.

## Hardening padrão

| Controle | Valor |
|---|---|
| IMDS | v2 obrigatório, hop limit 1 |
| Disco raiz | gp3, criptografado, apagado no terminate |
| Acesso | sem key pair, sem porta 22 — SSM Session Manager |
| Créditos CPU | `standard` (sem cobrança surpresa) |
| `ignore_changes` | `ami`, `user_data` |

## Entradas

| Nome | Tipo | Descrição |
|---|---|---|
| `instances` | map(object) | Definição de cada máquina (ver `variables.tf`) |
| `ami_id` | string | AMI Ubuntu |
| `subnet_id_by_tier` | map(string) | `public`/`core`/`app` -> subnet |
| `security_group_by_service` | map(string) | serviço -> SG |
| `instance_profile_name` | string | Instance profile |
| `enable_detailed_monitoring` | bool | default `false` |

## Saídas

`instance_ids`, `private_ips`, `primary_network_interface_ids`.
