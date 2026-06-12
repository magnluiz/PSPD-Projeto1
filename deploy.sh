#!/usr/bin/env bash
# PSPD — Épico 3
# Build das imagens Docker dentro do Minikube e deploy no cluster
# Pré-requisito: minikube e kubectl instalados e minikube rodando
#   minikube start

set -e

echo "=== PSPD Épico 3 — Deploy Minikube ==="

# ── 1. Aponta Docker para o daemon do Minikube ───────────────────────────
echo ""
echo "→ Configurando Docker para usar o daemon do Minikube..."
eval $(minikube docker-env)

# ── 2. Build das imagens ─────────────────────────────────────────────────
echo ""
echo "→ Build service-a (Python)..."
docker build -f service-a/Dockerfile -t pspd/service-a:latest .

echo ""
echo "→ Build service-b (Node.js)..."
docker build -f service-b/Dockerfile -t pspd/service-b:latest .

echo ""
echo "→ Build gateway (Go)..."
docker build -f gateway/Dockerfile -t  pspd/gateway:latest .

# ── 3. Apply manifests ───────────────────────────────────────────────────
echo ""
echo "→ Aplicando manifests Kubernetes..."
kubectl apply -f k8s/service-a.yaml
kubectl apply -f k8s/service-b.yaml
kubectl apply -f k8s/gateway.yaml

# ── 4. Aguarda pods ficarem prontos ──────────────────────────────────────
echo ""
echo "→ Aguardando pods..."
kubectl rollout status deployment/service-a --timeout=60s
kubectl rollout status deployment/service-b --timeout=60s
kubectl rollout status deployment/gateway   --timeout=60s

# ── 5. Mostra URL de acesso ──────────────────────────────────────────────
echo ""
echo "✅ Deploy concluído!"
echo ""
echo "URL do Gateway:"
minikube service gateway --url

echo ""
echo "Teste rápido (substitua a URL acima):"
echo "  curl \"\$(minikube service gateway --url)/add?a=3&b=7\""
echo "  curl \"\$(minikube service gateway --url)/factorial?a=5\""
