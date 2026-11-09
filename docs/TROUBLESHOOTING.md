# Troubleshooting

Primeiro passo sempre: `make logs NAME=<FAF_...>` e procurar `[faf] ERRO`.

| Sintoma | Causa provável | Diagnóstico | Correção |
|---|---|---|---|
| Máquinas privadas presas em "waiting egress" | NAT não funcional | `make logs NAME=FAF_GATEWAY`; no gateway: `sudo nft list ruleset`, `sysctl net.ipv4.ip_forward` | Confirmar `source_dest_check=false` no console; recriar o gateway (RUNBOOK §4) |
| <a id="ssm-não-conecta"></a>SSM não conecta | Agente sem saída 443, role ausente ou plugin local ausente | `aws ssm describe-instance-information --region us-east-1` | Checar instance profile `FAF_PROFILE_EC2_SSM`; checar NAT; instalar `session-manager-plugin` |
| `curl http://EIP/` dá timeout | Seu IP mudou | `curl -s https://checkip.amazonaws.com` | Atualizar `TF_VAR_allowed_ingress_cidrs` e aplicar |
| Firewall retorna 502 | Backends ainda em bootstrap ou fora | `make logs NAME=FAF_WEB_01`; no firewall `sudo tail /var/log/nginx/error.log` | Aguardar bootstrap; checar `FAF_SG_WEB` aceita origem `FAF_SG_FIREWALL` |
| AD_02 falha no join | DC primário não pronto ou DNS | Log do AD_02; `host -t SRV _ldap._tcp.ad.faf.internal 10.10.10.10` | Recriar o AD_02 após o AD_01 concluir |
| `kinit` falha com "Clock skew too great" | Hora dessincronizada | `chronyc tracking` | `sudo systemctl restart chrony` |
| Porta 53 ocupada no AD/DNS | systemd-resolved stub ativo | `sudo ss -lunp | grep :53` | AD: `systemctl disable --now systemd-resolved`; DNS: `DNSStubListener=no` |
| Secundário DNS sem zona | AXFR bloqueado | `dig @10.10.10.20 faf.internal AXFR` a partir do secundário | Conferir `allow-transfer` em `/etc/bind/named.conf.local` do primário |
| LAMP "Erro ao acessar o banco" | Senha divergente do SSM | `sudo tail /var/log/apache2/error.log` | RUNBOOK §5 (rotação) |
| `Error acquiring the state lock` | Execução anterior interrompida | Ver ID do lock na mensagem | `terraform -chdir=<stack> force-unlock <ID>` — só se tiver certeza de que ninguém está aplicando |
| `Unable to find remote state` / `outputs` vazio na 02 ou 03 | Stack anterior não aplicada, ou `TF_STATE_BUCKET`/`TF_STATE_PREFIX` divergentes | `aws s3 ls s3://$TF_STATE_BUCKET/$TF_STATE_PREFIX/` | Aplicar na ordem 01 → 02 → 03; conferir `.env` |
| `Unsupported attribute` em `local.network.*` / `local.security.*` | Saída removida/renomeada na stack anterior | `terraform -chdir=01-network-stack output` | Restaurar o nome em `outputs.tf` (é contrato entre stacks) |
| `DependencyViolation` ao destruir 01 ou 02 | Ordem de destroy invertida | — | `make destroy-all` (03 → 02 → 01) |
| `No value for required variable "state_bucket"` | Terraform rodado sem o Makefile | — | Usar `make ...` ou exportar `TF_VAR_state_bucket` |
| `InvalidParameterValue: Address ... in use` | IP fixo colidindo | Plano de IPs em ARCHITECTURE §3 | Ajustar `ip_offset` dos serviços |
| Plan quer recriar tudo | Mudança de `project`/chaves do mapa `services` | Ler o plano | Não renomear chaves; usar `terraform state mv` se precisar |
| `Invalid value for variable services` | Serviço novo sem arquivo `ec2.<servico>.tf` | Mensagem da validação | RUNBOOK §3 (serviço novo) |
