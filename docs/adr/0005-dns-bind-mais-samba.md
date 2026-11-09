# ADR 0005 — BIND9 (faf.internal) + DNS do Samba (ad.faf.internal)

- **Status:** aceito
- **Data:** 2026-11-04

## Contexto
Requisitos pedem um serviço de DNS e um AD. O Samba AD DC exige ser autoritativo para a própria zona.

## Decisão
- FAF_DNS (BIND9) autoritativo para `faf.internal`, zona gerada pelo Terraform a partir do inventário (IPs fixos).
- Zona `ad.faf.internal` encaminhada (`forward only`) para os DCs.
- Primário/secundário via AXFR + NOTIFY.
- VPC mantém o AmazonProvidedDNS no DHCP para não criar dependência de boot.

## Consequências
- (+) Delegação clara de responsabilidade; zona sempre coerente com o inventário.
- (+) Serial SOA determinístico (hash dos registros): não muda sem mudar o conteúdo.
- (−) `dnssec-validation no` (o TLD `.internal` não tem cadeia DNSSEC pública).
- (−) Escalar serviços exige recriar FAF_DNS para regenerar a zona (RUNBOOK §3).
