# Segurança

## Controles implementados

| Domínio | Controle | Onde |
|---|---|---|
| Rede | Entrada única pelo FAF_FIREWALL, restrita a `allowed_ingress_cidrs` | `02-security-stack/sg.firewall.tf` |
| Rede | WEB/LAMP aceitam só o SG do firewall (referência de SG) | `02-security-stack/sg.web.tf`, `sg.lamp.tf` |
| Rede | SG default sem regras | `01-network-stack/vpc.default-security-group.tf` |
| Rede | nftables default-drop no firewall e no gateway | `03-compute-stack/templates/` |
| Acesso | Sem SSH, sem key pair, sem bastion — SSM Session Manager | `02-security-stack/iam.ec2-role.tf`, `modules/ec2_instance` |
| Instância | IMDSv2 obrigatório, hop limit 1 | `modules/ec2_instance` |
| Instância | EBS gp3 criptografado | `modules/ec2_instance` |
| Instância | `unattended-upgrades` | `03-compute-stack/templates/common.sh.tftpl` |
| Aplicação | MySQL só em loopback, root via `auth_socket`, usuário de app com SELECT/INSERT | `03-compute-stack/templates/lamp.sh.tftpl` |
| Aplicação | Headers de segurança, `server_tokens off`, `expose_php Off` | templates web/lamp/firewall |
| Segredos | Gerados pelo Terraform, SSM SecureString, nunca no user_data/git | `02-security-stack/ssm.*.tf` |
| IAM | Leitura apenas de `/faf/lab/*` | `02-security-stack/iam.ec2-role.tf` |
| State | S3 privado, versionado, SSE, TLS obrigatório, lock nativo | `00-remote-state-stack/` |
| State | Um state por stack: um erro na 03 não corrompe rede nem IAM | `*/backend.tf` |
| Supply chain | Dependabot para actions e providers; `.terraform.lock.hcl` versionado | `.github/` |

## Segredos: ciclo de vida

```
random_password ──► aws_ssm_parameter (SecureString, chave aws/ssm)
                         │
                         └─► EC2 (role FAF_ROLE_EC2_SSM) ─► aws ssm get-parameter no boot
```

**Risco residual:** `random_password` grava o valor no state da 02-security-stack. Mitigação: bucket de state
criptografado e restrito. Evolução recomendada: recursos efêmeros + argumentos
*write-only* (`value_wo`, Terraform ≥ 1.11), que mantêm o segredo fora do state.

## Exceções do Checkov (CI)

Resultado local da varredura: **256 checks aprovados**, 0 falhas. `CKV_AWS_260` é suprimido só nas regras `web_from_firewall` e `lamp_from_firewall` (comentário inline: a origem é o SG do firewall, não 0.0.0.0/0).

| Check | Motivo da exceção |
|---|---|
| `CKV_AWS_126` detailed monitoring | Custo; habilitável por `enable_detailed_monitoring` |
| `CKV2_AWS_11` VPC flow logs | Custo; habilitável por `enable_flow_logs` |
| `CKV_AWS_144` replicação cross-region do bucket | Laboratório de região única |
| `CKV_AWS_145` S3 com KMS CMK | SSE-S3 suficiente para o laboratório |
| `CKV_AWS_18` access logging do bucket | Custo/ruído |
| `CKV2_AWS_62` notificações do bucket | Não aplicável |
| `CKV_AWS_337` SSM com KMS CMK | Chave gerenciada `aws/ssm` suficiente para o laboratório |
| `CKV_AWS_88` EC2 com IP público | Intencional: FAF_FIREWALL (entrada) e FAF_GATEWAY (NAT) precisam de IP público |
| `CKV_AWS_382` egress irrestrito | Intencional apenas no FAF_SG_GATEWAY (é o NAT) |
| `CKV_AWS_158` log group sem KMS CMK | Flow logs opcionais; chave padrão do CloudWatch |
| `CKV_AWS_338` retenção < 1 ano | Laboratório: 14 dias configuráveis |
| `CKV2_AWS_5` SG não anexado | Falso positivo: os SGs (02) são anexados às EC2 em outra stack (03) via remote state, o que a análise estática não enxerga |

## Melhorias para produção

1. Uma role IAM por serviço (cada máquina lê só o seu segredo).
2. KMS CMK com rotação para SSM e state.
3. Segredos *write-only* (fora do state).
4. AWS Network Firewall / ALB + WAF no lugar do firewall em VM.
5. VPC Endpoints (ssm, ssmmessages, ec2messages) para SSM sem passar pelo NAT.
6. GuardDuty, Security Hub e CloudTrail organizacional.
7. Permissões de deploy separadas por stack (quem aplica a 03 não precisa de IAM).
8. CI com OIDC (`aws-actions/configure-aws-credentials`) e `plan` automatizado em PR.
