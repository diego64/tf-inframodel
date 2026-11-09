# Custos

Preços on-demand de referência em `us-east-1` (Linux). Confirme no
[AWS Pricing Calculator](https://calculator.aws/) antes de subir.

## Configuração padrão (16 VMs)

| Recurso | Qtd | Preço unitário | USD/hora | USD/mês (730 h) |
|---|---|---|---|---|
| t3.micro (GATEWAY, FIREWALL, DNS×2, WEB×5) | 9 | 0,0104/h | 0,094 | 68,3 |
| t3.small (AD×2, LAMP×5) | 7 | 0,0208/h | 0,146 | 106,3 |
| EBS gp3 | 230 GiB | 0,08/GiB-mês | — | 18,4 |
| IPv4 público (gateway + EIP firewall) | 2 | 0,005/h | 0,010 | 7,3 |
| SSM Parameter Store (standard) | 2 | grátis | — | 0 |
| S3 (state) | < 1 MB | — | — | ~0 |
| Transferência de saída | variável | 0,09/GB após 100 GB | — | ~0 em demo |
| **Total** | | | **~0,27** (com EBS rateado) | **~200** |

## Cenários

| Cenário | Custo aproximado |
|---|---|
| Demo de 4 h (16 VMs) | ~USD 1 |
| 1 dia útil (8 h) | ~USD 2 |
| Esquecido ligado por 1 mês | ~USD 200 |
| `03-compute-stack/examples/minimal.tfvars` por 1 mês | ~USD 70 |

## Como reduzir

1. **Destruir após a demonstração** — `make destroy-all`. Maior economia de todas.
   Alternativa: destruir só a `03-compute-stack` (onde está ~100% do custo) e manter rede/IAM para o próximo deploy.
2. `03-compute-stack/examples/minimal.tfvars` para desenvolvimento.
3. Instâncias Graviton (`t4g.*`) custam ~20% menos — exige AMI arm64 (alterar o filtro `architecture` em `03-compute-stack/data.ami.tf`).
4. AWS Budgets com alerta em USD 20 na conta do laboratório.

> NAT instance (`FAF_GATEWAY`, ~USD 7,6/mês) foi escolhida em vez do NAT Gateway
> (~USD 33/mês + USD 0,045/GB). Ver [ADR 0002](adr/0002-nat-instance.md).
