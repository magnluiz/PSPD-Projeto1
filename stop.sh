#!/usr/bin/env bash
# PSPD — Projeto 1
# Para todos os workloads e o cluster Minikube de forma ordenada.
# Uso: ./stop.sh

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

info() { echo -e "${BLUE}  → $1${NC}"; }
ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\n${BLUE}=== PSPD Épico 3 — Stop ===${NC}"

# 1. Remove workloads gracefully (kubectl needs apiserver alive)
if minikube status &>/dev/null; then
  info "Removendo workloads Kubernetes..."
  kubectl delete -f "$SCRIPT_DIR/k8s/" --ignore-not-found
  ok "Pods removidos"
else
  info "Minikube não está rodando, pulando kubectl delete"
fi

# 2. Stop the cluster
info "Parando Minikube..."
minikube stop
ok "Minikube parado"

echo ""
echo -e "${GREEN}Tudo parado. Para subir novamente: ./deploy.sh${NC}"
