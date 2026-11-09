# ADR 0003 — AZ única

- **Status:** aceito
- **Data:** 2026-11-04

## Decisão
Todas as subnets em `us-east-1a`.

## Motivo
Laboratório de portfólio: menor custo e diagrama simples. AD e DNS já demonstram redundância
lógica (2 DCs, primário/secundário), ainda que na mesma AZ.

## Consequências
Falha da AZ derruba o laboratório inteiro. Para multi-AZ: transformar `subnet_cidrs` em mapa
por AZ, distribuir `index` entre AZs e substituir FAF_FIREWALL/FAF_GATEWAY por ALB + NAT Gateway por AZ.
