#!/usr/bin/env bash
# PSPD — Projeto 1
# Instala todas as dependências necessárias para rodar o projeto completo:
#   Python 3, Node.js 22, Go, gRPC libs, protoc, Docker, Minikube, kubectl
#
# Testado em Ubuntu 22.04 / 24.04
# Execute com: chmod +x install_deps.sh && ./install_deps.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }
info() { echo -e "${BLUE}  → $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# ── Verifica que está rodando no Ubuntu/Debian ────────────────────────────
if ! command -v apt &>/dev/null; then
  echo -e "${RED}Este script requer apt (Ubuntu/Debian).${NC}"
  exit 1
fi

# ── Versões alvo ─────────────────────────────────────────────────────────
GO_VERSION="1.24.4"
NODE_MAJOR="22"

section "Atualizando apt"
sudo apt-get update -qq
ok "apt atualizado"

# ─────────────────────────────────────────────────────────────────────────
section "Python 3 + pip + venv + grpcio"
# ─────────────────────────────────────────────────────────────────────────
if command -v python3 &>/dev/null; then
  ok "python3 já instalado: $(python3 --version)"
else
  info "Instalando Python 3..."
  sudo apt-get install -y python3 python3-pip python3-venv
  ok "Python instalado: $(python3 --version)"
fi

info "Instalando grpcio + grpcio-tools globalmente..."
pip3 install --break-system-packages --quiet grpcio grpcio-tools
ok "grpcio instalado: $(pip3 show grpcio | grep Version)"

# ─────────────────────────────────────────────────────────────────────────
section "Node.js $NODE_MAJOR"
# ─────────────────────────────────────────────────────────────────────────
if node --version 2>/dev/null | grep -q "^v${NODE_MAJOR}"; then
  ok "Node.js já instalado: $(node --version)"
else
  info "Instalando Node.js $NODE_MAJOR via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | sudo -E bash - -qq
  sudo apt-get install -y nodejs
  ok "Node.js instalado: $(node --version)"
fi
ok "npm: $(npm --version)"

# ─────────────────────────────────────────────────────────────────────────
section "Go $GO_VERSION"
# ─────────────────────────────────────────────────────────────────────────
INSTALLED_GO=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || true)
if [ "$INSTALLED_GO" = "$GO_VERSION" ]; then
  ok "Go já instalado: $INSTALLED_GO"
else
  info "Instalando Go $GO_VERSION..."
  GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
  curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
  rm "/tmp/${GO_TARBALL}"

  # PATH para a sessão atual
  export PATH="$PATH:/usr/local/go/bin"

  # PATH permanente
  if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.bashrc
  fi
  if ! grep -q '/usr/local/go/bin' ~/.profile; then
    echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.profile
  fi
  ok "Go instalado: $(go version)"
fi

# ─────────────────────────────────────────────────────────────────────────
section "protoc (Protocol Buffers compiler)"
# ─────────────────────────────────────────────────────────────────────────
if command -v protoc &>/dev/null; then
  ok "protoc já instalado: $(protoc --version)"
else
  info "Instalando protoc..."
  sudo apt-get install -y protobuf-compiler
  ok "protoc instalado: $(protoc --version)"
fi

# ─────────────────────────────────────────────────────────────────────────
section "protoc plugins Go (protoc-gen-go + protoc-gen-go-grpc)"
# ─────────────────────────────────────────────────────────────────────────
export PATH="$PATH:$(go env GOPATH)/bin"

if ! grep -q 'GOPATH.*bin' ~/.bashrc; then
  echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> ~/.bashrc
fi

info "Instalando protoc-gen-go..."
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
ok "protoc-gen-go instalado"

info "Instalando protoc-gen-go-grpc..."
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
ok "protoc-gen-go-grpc instalado"

# ─────────────────────────────────────────────────────────────────────────
section "Docker"
# ─────────────────────────────────────────────────────────────────────────
if command -v docker &>/dev/null; then
  ok "Docker já instalado: $(docker --version)"
else
  info "Instalando Docker..."
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  ok "Docker instalado: $(docker --version)"
fi

if groups $USER | grep -q docker; then
  ok "Usuário $USER já está no grupo docker"
else
  info "Adicionando $USER ao grupo docker (requer novo login para ter efeito)..."
  sudo usermod -aG docker $USER
  warn "Faça logout e login (ou rode 'newgrp docker') para usar Docker sem sudo"
fi

# ─────────────────────────────────────────────────────────────────────────
section "Minikube"
# ─────────────────────────────────────────────────────────────────────────
if command -v minikube &>/dev/null; then
  ok "Minikube já instalado: $(minikube version --short)"
else
  info "Instalando Minikube..."
  curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    -o /tmp/minikube-linux-amd64
  sudo install /tmp/minikube-linux-amd64 /usr/local/bin/minikube
  rm /tmp/minikube-linux-amd64
  ok "Minikube instalado: $(minikube version --short)"
fi

# ─────────────────────────────────────────────────────────────────────────
section "kubectl"
# ─────────────────────────────────────────────────────────────────────────
if command -v kubectl &>/dev/null; then
  ok "kubectl já instalado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  info "Instalando kubectl..."
  KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
  curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /tmp/kubectl
  sudo install /tmp/kubectl /usr/local/bin/kubectl
  rm /tmp/kubectl
  ok "kubectl instalado: $(kubectl version --client --short 2>/dev/null || true)"
fi

# ─────────────────────────────────────────────────────────────────────────
section "Dependências do projeto (npm + pip)"
# ─────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/service-b/package.json" ]; then
  info "Instalando dependências Node.js em service-b/..."
  (cd "$SCRIPT_DIR/service-b" && npm install --quiet)
  ok "service-b npm deps instaladas"
else
  warn "service-b/package.json não encontrado — rode 'npm install' manualmente em service-b/"
fi

if [ -f "$SCRIPT_DIR/service-a/requirements.txt" ]; then
  info "Instalando dependências Python em service-a/..."
  pip3 install --break-system-packages --quiet -r "$SCRIPT_DIR/service-a/requirements.txt"
  ok "service-a pip deps instaladas"
else
  warn "service-a/requirements.txt não encontrado — rode 'pip install grpcio grpcio-tools' manualmente"
fi

if [ -f "$SCRIPT_DIR/gateway/go.mod" ]; then
  info "Baixando módulos Go em gateway/..."
  (cd "$SCRIPT_DIR/gateway" && go mod download)
  ok "gateway Go modules baixados"
else
  warn "gateway/go.mod não encontrado — rode 'go mod download' manualmente em gateway/"
fi

# ─────────────────────────────────────────────────────────────────────────
section "Resumo"
# ─────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Tudo instalado! Versões:${NC}"
echo "  python3:   $(python3 --version)"
echo "  node:      $(node --version)"
echo "  go:        $(go version | awk '{print $3}')"
echo "  protoc:    $(protoc --version)"
echo "  docker:    $(docker --version | awk '{print $3}' | tr -d ',')"
echo "  minikube:  $(minikube version --short)"
echo "  kubectl:   $(kubectl version --client -o json 2>/dev/null | grep gitVersion | head -1 | tr -d ' ",' | cut -d: -f2 || echo 'ok')"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "  1. Se Docker acabou de ser instalado: newgrp docker  (ou faça logout/login)"
echo "  2. minikube start --driver=docker"
echo "  3. ./generate.sh"
echo "  4. ./deploy.sh"
