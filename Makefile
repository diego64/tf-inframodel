# =============================================================================
# Makefile — ciclo Terraform por stack (lê variáveis do .env)
#   make help
#   make plan  STACK=01-network-stack
#   make apply STACK=01-network-stack
# Ordem de deploy: 00 -> 01 -> 02 -> 03   |   Ordem de destroy: 03 -> 02 -> 01
# =============================================================================
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

ifneq (,$(wildcard .env))
include .env
export
endif

TF              ?= terraform
STATE_STACK     := 00-remote-state-stack
STACKS          := 01-network-stack 02-security-stack 03-compute-stack
STACKS_REVERSE  := 03-compute-stack 02-security-stack 01-network-stack
COMPUTE         := 03-compute-stack
STACK           ?=
PLAN_FILE       ?= tfplan
VAR_FILE        ?=
VAR_ARG         := $(if $(VAR_FILE),-var-file=$(VAR_FILE),)
TF_STATE_PREFIX ?= faf-lab
CHECKOV_SKIP    := CKV_AWS_126,CKV2_AWS_11,CKV_AWS_144,CKV_AWS_145,CKV_AWS_18,CKV2_AWS_62,CKV_AWS_337,CKV_AWS_88,CKV_AWS_382,CKV_AWS_158,CKV_AWS_338,CKV2_AWS_5

# Injetados nas stacks que leem remote state (02 e 03)
export TF_VAR_state_bucket     := $(TF_STATE_BUCKET)
export TF_VAR_state_key_prefix := $(TF_STATE_PREFIX)

.PHONY: help stacks check-env require-stack bootstrap init fmt fmt-check validate lint security check \
        plan apply destroy deploy-all destroy-all output inventory ssm logs clean

help: ## Lista os comandos
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

stacks: ## Lista as stacks na ordem de deploy
	@echo "$(STATE_STACK) (1x, state local)"; for s in $(STACKS); do echo "$$s"; done

check-env: ## Verifica .env e credenciais AWS
	@test -f .env || { echo "Crie o .env: cp .env.example .env"; exit 1; }
	@aws sts get-caller-identity --query 'Arn' --output text

require-stack:
	@test -n "$(STACK)" && test -d "$(STACK)" || { echo "Informe STACK=<$(STACKS)>"; exit 1; }

bootstrap: check-env ## [1x] Cria o bucket do remote state (00-remote-state-stack)
	$(TF) -chdir=$(STATE_STACK) init
	$(TF) -chdir=$(STATE_STACK) apply -var="project=$(TF_VAR_project)" -var="region=$(AWS_REGION)"
	@echo ">> Copie 'state_bucket' para TF_STATE_BUCKET no .env"

init: check-env require-stack ## Inicializa a STACK (backend S3, key por stack)
	$(TF) -chdir=$(STACK) init -upgrade \
	  -backend-config="bucket=$(TF_STATE_BUCKET)" \
	  -backend-config="key=$(TF_STATE_PREFIX)/$(STACK).tfstate" \
	  -backend-config="region=$(AWS_REGION)" \
	  -backend-config="encrypt=true" \
	  -backend-config="use_lockfile=true"

fmt: ## Formata todos os .tf
	$(TF) fmt -recursive

fmt-check: ## Falha se algum .tf estiver fora do padrão
	$(TF) fmt -recursive -check -diff

validate: ## Valida todas as stacks (sem backend)
	@for s in $(STATE_STACK) $(STACKS); do \
	  echo "== $$s"; \
	  $(TF) -chdir=$$s init -backend=false -input=false >/dev/null; \
	  $(TF) -chdir=$$s validate; \
	done

lint: ## TFLint em todas as stacks e módulos
	tflint --init --config "$(CURDIR)/.tflint.hcl"
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

security: ## Checkov
	checkov -d . --framework terraform --quiet --compact --skip-check $(CHECKOV_SKIP)

check: fmt-check validate lint security ## Todas as verificações locais

plan: require-stack ## Plano da STACK salvo em <STACK>/tfplan (VAR_FILE relativo à stack)
	$(TF) -chdir=$(STACK) plan $(VAR_ARG) -out=$(PLAN_FILE)

apply: require-stack ## Aplica EXATAMENTE o plano salvo da STACK
	@test -f $(STACK)/$(PLAN_FILE) || { echo "Rode 'make plan STACK=$(STACK)' antes"; exit 1; }
	$(TF) -chdir=$(STACK) apply $(PLAN_FILE)
	@rm -f $(STACK)/$(PLAN_FILE)

destroy: require-stack ## Destrói a STACK (respeite a ordem 03 -> 02 -> 01)
	$(TF) -chdir=$(STACK) destroy $(VAR_ARG)

deploy-all: check-env ## init + plan + confirmação + apply em 01, 02, 03
	@for s in $(STACKS); do \
	  $(MAKE) --no-print-directory init plan STACK=$$s; \
	  read -r -p ">> Aplicar $$s? [s/N] " ans; [ "$$ans" = "s" ] || { echo "Interrompido em $$s"; exit 1; }; \
	  $(MAKE) --no-print-directory apply STACK=$$s; \
	done

destroy-all: check-env ## Destrói 03, 02 e 01 (cada uma pede confirmação)
	@for s in $(STACKS_REVERSE); do $(MAKE) --no-print-directory init destroy STACK=$$s; done

output: ## Saídas da STACK (padrão: compute)
	$(TF) -chdir=$(or $(STACK),$(COMPUTE)) output

inventory: ## Tabela Name / IP / ID / hostname
	@$(TF) -chdir=$(COMPUTE) output -json instances | jq -r 'to_entries[] | [.key, .value.private_ip, .value.id, .value.hostname] | @tsv' | sort | column -t

ssm: ## Shell via SSM. Ex.: make ssm NAME=FAF_AD_01
	@test -n "$(NAME)" || { echo "Informe NAME=FAF_<SERVICO>"; exit 1; }
	aws ssm start-session --region $(AWS_REGION) --target "$$($(TF) -chdir=$(COMPUTE) output -json instances | jq -r '.["$(NAME)"].id')"

logs: ## Log de bootstrap via SSM. Ex.: make logs NAME=FAF_FIREWALL
	@test -n "$(NAME)" || { echo "Informe NAME=FAF_<SERVICO>"; exit 1; }
	@ID="$$($(TF) -chdir=$(COMPUTE) output -json instances | jq -r '.["$(NAME)"].id')"; \
	CMD_ID="$$(aws ssm send-command --region $(AWS_REGION) --instance-ids $$ID --document-name AWS-RunShellScript \
	  --parameters 'commands=["tail -n 80 /var/log/faf-bootstrap.log","ls -l /var/lib/faf/"]' --query 'Command.CommandId' --output text)"; \
	sleep 4; \
	aws ssm get-command-invocation --region $(AWS_REGION) --command-id $$CMD_ID --instance-id $$ID --query 'StandardOutputContent' --output text

clean: ## Remove .terraform e planos de todas as stacks
	@for s in $(STATE_STACK) $(STACKS); do rm -rf $$s/.terraform $$s/$(PLAN_FILE); done
