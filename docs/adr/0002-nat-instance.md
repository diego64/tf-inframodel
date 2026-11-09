# ADR 0002 — FAF_GATEWAY como NAT instance (e não NAT Gateway)

- **Status:** aceito
- **Data:** 2026-11-04

## Contexto
As subnets privadas precisam de saída para `apt`, `snap` e endpoints SSM. Requisito explícito de uma máquina "GATEWAY".

## Opções
| Opção | Custo/mês | Gerenciamento | HA |
|---|---|---|---|
| **NAT instance (t3.micro)** | ~USD 7,6 | Nós (patch, nftables) | Não |
| NAT Gateway | ~USD 33 + USD 0,045/GB | AWS | Na AZ |
| VPC Endpoints | ~USD 7,3 por endpoint/AZ | AWS | Sim, mas não cobre `apt` |

## Decisão
NAT instance com `source_dest_check = false`, `ip_forward` e masquerade em nftables.

## Consequências
- (+) Barato e didático: demonstra roteamento Linux, NAT e firewall stateful.
- (−) SPOF: se o gateway cai, as privadas perdem saída (os serviços internos continuam funcionando).
- Produção: NAT Gateway por AZ.
