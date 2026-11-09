# ADR 0001 — Nomenclatura FAF_<SERVICO>

- **Status:** aceito
- **Data:** 2026-11-04

## Contexto
Requisito: todos os recursos seguem `FAF_NOMEDOSERVICO`.

## Decisão
| Escopo | Padrão |
|---|---|
| Tag `Name` (instância única) | `FAF_<SERVICO>` |
| Tag `Name` (múltiplas) | `FAF_<SERVICO>_NN` |
| Recursos de infra | `FAF_<TIPO>_<NOME>` (`FAF_SG_WEB`, `FAF_SUBNET_APP`) |
| Chave do `for_each` | `<servico>-NN` (estável) |

A chave do `for_each` é separada da tag `Name`: escalar `firewall` de 1 para 2 muda apenas a tag
(`FAF_FIREWALL` → `FAF_FIREWALL_01`, update in-place), sem recriar a máquina.

## Exceções (impostas por regras externas)
- **Hostname do SO**: `faf-<servico>-NN` — `_` é inválido em hostnames (RFC 1123/952) e o Samba AD recusa.
- **Bucket S3**: `faf-tfstate-<conta>-<região>` — S3 não aceita maiúsculas nem `_`.

## Consequências
Nome humano consistente no console; identificadores técnicos válidos em DNS, Kerberos e S3.
