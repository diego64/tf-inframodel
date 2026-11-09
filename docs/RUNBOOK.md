# Runbook operacional

Cada ação tem: **quando usar → comando → resultado esperado → rollback**.

| Ação | Stack afetada |
|---|---|
| Acessar/validar máquinas | 03-compute-stack (leitura) |
| Escalar / recriar máquinas | 03-compute-stack |
| Liberar novo IP no firewall | 02-security-stack |
| Rotacionar segredos | 02-security-stack + comando nas VMs |
| Mudar CIDR / AZ | 01-network-stack (**recria tudo**: destroy 03 → 02 → 01) |

Comandos `terraform` brutos usam `-chdir=<stack>`; os `make` usam `STACK=<stack>`.

---

## 1. Acessar uma máquina

```bash
make ssm NAME=FAF_AD_01                 # shell interativo (usuário ssm-user, sudo disponível)
make logs NAME=FAF_LAMP_03              # últimas 80 linhas do bootstrap, sem abrir shell
terraform -chdir=03-compute-stack output ssm_connect_commands   # comando bruto de cada máquina
```

Não existe SSH. Se o SSM não conecta, ver [TROUBLESHOOTING](TROUBLESHOOTING.md#ssm-não-conecta).

---

## 2. Validação por serviço

### FAF_GATEWAY (NAT)
```bash
# em qualquer máquina privada (ex.: FAF_WEB_01)
curl -s https://checkip.amazonaws.com    # deve retornar o IP público do FAF_GATEWAY
# no próprio gateway
sudo nft list table ip nat               # regra masquerade presente
sysctl net.ipv4.ip_forward               # = 1
```

### FAF_FIREWALL
```bash
FW=$(terraform -chdir=03-compute-stack output -json firewall_public_ips | jq -r '.FAF_FIREWALL')
curl -s http://$FW/healthz                            # ok
for i in 1 2 3 4 5; do curl -sI http://$FW/ | grep X-FAF-Backend; done   # alterna entre os 5 WEB
nc -zv -w3 $FW 22                                     # deve FALHAR (sem SSH)
# na máquina
sudo nft list ruleset | head -40
sudo nginx -T | grep -A6 upstream
```

### FAF_AD
```bash
# em FAF_AD_01
sudo samba-tool domain level show
sudo samba-tool drs showrepl             # replicação com FAF_AD_02 sem erros
host -t SRV _ldap._tcp.ad.faf.internal 127.0.0.1   # 2 registros (um por DC)
PASS=$(aws ssm get-parameter --name /faf/lab/ad/admin_password --with-decryption --query Parameter.Value --output text --region us-east-1)
echo "$PASS" | kinit administrator@AD.FAF.INTERNAL && klist
sudo samba-tool user create joao.silva --random-password   # teste de escrita no diretório
```

### FAF_DNS
```bash
# de qualquer máquina da VPC
dig +short @10.10.10.20 faf-web-01.faf.internal          # 10.10.20.40
dig +short @10.10.10.21 faf-web-01.faf.internal          # mesmo valor (secundário)
dig +short @10.10.10.20 SRV _kerberos._tcp.ad.faf.internal   # forward para o AD
dig +short @10.10.10.20 SOA faf.internal                 # serial igual nos dois servidores
```

### FAF_LAMP
```bash
curl -s http://$FW:8080/ | grep -E '<h1>|Visitas'
# na máquina
sudo mysql -e "SELECT COUNT(*) FROM faf_app.visits;"
ss -tlnp | grep 3306                     # apenas 127.0.0.1:3306
```

### FAF_WEB
```bash
curl -s http://$FW/ | grep '<h1>'
```

---

## 3. Escalar um serviço

**Quando:** mudar quantidade/tipo de máquina.

```bash
# 03-compute-stack/terraform.tfvars
services = { ..., web = { count = 8, instance_type = "t3.micro", tier = "app", ip_offset = 40, volume_size = 10 } }

make plan STACK=03-compute-stack && make apply STACK=03-compute-stack
```

Serviço **novo** (ex.: `monitoring`): adicione a chave em `services`, o template
`templates/monitoring.sh.tftpl`, o arquivo `ec2.monitoring.tf` (copie um existente),
o `sg.monitoring.tf` na 02 e ajuste a validação de `services` em `variables.tf`.

**Atenção:** o FAF_FIREWALL e o FAF_DNS foram configurados no primeiro boot com a lista
antiga de IPs (`ignore_changes = [user_data]`). Para propagar os novos nós, recrie esses
dois serviços sem estado:

```bash
terraform -chdir=03-compute-stack plan -out=tfplan \
  -replace='module.ec2_firewall.aws_instance.this["firewall-01"]' \
  -replace='module.ec2_dns.aws_instance.this["dns-01"]' \
  -replace='module.ec2_dns.aws_instance.this["dns-02"]'
terraform -chdir=03-compute-stack apply tfplan
```

O EIP é reassociado automaticamente ao novo FAF_FIREWALL. Indisponibilidade: ~3 min.

**Rollback:** voltar o `count` e aplicar.

---

## 3.1 Liberar um novo IP no FAF_FIREWALL

```bash
# .env
TF_VAR_allowed_ingress_cidrs=["203.0.113.10/32","198.51.100.7/32"]
make plan STACK=02-security-stack && make apply STACK=02-security-stack
```

Só a 02 muda (regras de SG). Nenhuma máquina é recriada.

---

## 4. Reaplicar o bootstrap de uma máquina

**Quando:** você mudou um template em `03-compute-stack/templates/` ou a máquina ficou inconsistente.

```bash
# endereço = module.ec2_<servico>.aws_instance.this["<servico>-NN"]
terraform -chdir=03-compute-stack plan -out=tfplan -replace='module.ec2_web.aws_instance.this["web-03"]'
terraform -chdir=03-compute-stack apply tfplan
```

| Serviço | Pode recriar sem perda? |
|---|---|
| gateway | Sim (saída das privadas cai por ~2 min) |
| firewall | Sim (site fora por ~3 min) |
| dns | Sim (zona é regenerada pelo Terraform) |
| web | Sim |
| lamp | **Não** — o MySQL local é perdido. Faça backup antes: `sudo mysqldump faf_app > /tmp/faf_app.sql` |
| ad | **Não para o AD_01** sem antes transferir as roles FSMO para o AD_02 (`samba-tool fsmo transfer --role=all`). Recriar o AD_02 exige remover o DC antigo: `samba-tool domain demote --remove-other-dead-server=faf-ad-02` |

---

## 5. Rotacionar segredos

### Senha do banco (FAF_LAMP)
```bash
terraform -chdir=02-security-stack plan -out=tfplan -replace=random_password.lamp_db
terraform -chdir=02-security-stack apply tfplan
# em cada FAF_LAMP_NN (ou via SSM Run Command em lote):
NEW=$(aws ssm get-parameter --name /faf/lab/lamp/db_password --with-decryption --query Parameter.Value --output text --region us-east-1)
sudo mysql -e "ALTER USER 'faf_app'@'localhost' IDENTIFIED BY '$NEW';"
sudo sed -i "s|^db_pass .*|db_pass = \"$NEW\"|" /etc/faf/app.ini
```

### Senha do Administrator (FAF_AD)
```bash
terraform -chdir=02-security-stack plan -out=tfplan -replace=random_password.ad_admin
terraform -chdir=02-security-stack apply tfplan
# em FAF_AD_01
NEW=$(aws ssm get-parameter --name /faf/lab/ad/admin_password --with-decryption --query Parameter.Value --output text --region us-east-1)
sudo samba-tool user setpassword administrator --newpassword="$NEW"
```

Atualizar o SSM sem atualizar o serviço deixa os dois divergentes — execute as duas etapas juntas.

---

## 6. Atualizações de sistema e AMI

- **Patches de segurança**: `unattended-upgrades` ativo em todas as VMs.
- **Patch manual em lote**:
  ```bash
  aws ssm send-command --region us-east-1 --document-name AWS-RunShellScript \
    --targets Key=tag:Project,Values=FAF \
    --parameters 'commands=["apt-get update","DEBIAN_FRONTEND=noninteractive apt-get -y upgrade"]'
  ```
- **Nova AMI**: o `ami` está em `ignore_changes`. Para adotar a AMI mais recente, recrie
  as máquinas desejadas com `-replace` (ver §4).

---

## 7. Detecção de drift

```bash
for s in 01-network-stack 02-security-stack 03-compute-stack; do
  echo "== $s"; terraform -chdir=$s plan -detailed-exitcode -refresh-only -input=false >/dev/null; echo "exit=$?"
done
# 0 = sem mudanças | 2 = drift detectado | 1 = erro
```

Alterações feitas pelo console da AWS aparecem aqui. Corrija no código, nunca no console.

---

## 8. Remover tudo (inclusive o state)

```bash
make destroy-all                      # 03 -> 02 -> 01
# o bucket tem prevent_destroy; remova a proteção em 00-remote-state-stack/s3.state-bucket.tf, então:
aws s3api delete-objects --bucket "$TF_STATE_BUCKET" \
  --delete "$(aws s3api list-object-versions --bucket "$TF_STATE_BUCKET" \
  --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)"
terraform -chdir=00-remote-state-stack destroy
```

---

## 9. Registro de mudanças

Toda alteração de infraestrutura segue o fluxo:

1. Branch + PR com descrição do impacto (blast radius, rollback).
2. CI verde (`terraform-ci`).
3. `make plan STACK=<stack>` anexado ao PR — **uma stack por PR** sempre que possível.
4. `make apply STACK=<stack>` do plano aprovado, na ordem 01 → 02 → 03.
5. Entrada no [`CHANGELOG.md`](../CHANGELOG.md).
