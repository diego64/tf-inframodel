# ADR 0004 — MySQL local em cada FAF_LAMP

- **Status:** aceito (com ressalva)
- **Data:** 2026-11-04

## Contexto
Requisito: "máquina Linux para hospedar um site PHP com banco de dados MySQL" — banco no mesmo host.

## Decisão
Cada FAF_LAMP_NN roda Apache + PHP + MySQL próprio, ouvindo só em loopback.
O FAF_FIREWALL usa `ip_hash` para o mesmo cliente cair sempre no mesmo nó.

## Consequências
- (+) Atende o requisito literal; cada nó é autocontido.
- (−) **Os 5 bancos são independentes**: dados divergem entre nós. `ip_hash` só mascara isso para o mesmo IP de origem.
- (−) Recriar o nó perde os dados (sem backup automático).

## Alternativas para produção
1. Amazon RDS for MySQL Multi-AZ, LAMP vira stateless.
2. Um nó `FAF_MYSQL` dedicado + réplica.
