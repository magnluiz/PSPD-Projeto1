#!/usr/bin/env bash
# PSPD — Projeto 1
# Gera os stubs gRPC a partir de proto/calc.proto para:
#   • service-a/        → calc_pb2.py + calc_pb2_grpc.py  (Python)
#   • benchmark/        → calc_pb2.py + calc_pb2_grpc.py  (Python)  ← novo
#   • gateway/calc_grpc → calc.pb.go + calc_grpc.pb.go    (Go)

set -e

PROTO_FILE="proto/calc.proto"
PROTO_DIR="proto"

echo "=== Gerando stubs gRPC ==="

# ── Python — service-a ─────────────────────────────────────────────────────
echo "→ Python (service-a)..."
python3 -m grpc_tools.protoc \
  -I"${PROTO_DIR}" \
  --python_out=service-a \
  --grpc_python_out=service-a \
  "${PROTO_FILE}"

# ── Python — benchmark ────────────────────────────────────────────────────
if [ -d "benchmark" ]; then
  echo "→ Python (benchmark)..."
  python3 -m grpc_tools.protoc \
    -I"${PROTO_DIR}" \
    --python_out=benchmark \
    --grpc_python_out=benchmark \
    "${PROTO_FILE}"
fi

# ── Go — gateway ──────────────────────────────────────────────────────────
echo "→ Go (gateway/calc_grpc)..."
mkdir -p gateway/calc_grpc
protoc \
  -I"${PROTO_DIR}" \
  --go_out=gateway/calc_grpc \
  --go_opt=paths=source_relative \
  --go-grpc_out=gateway/calc_grpc \
  --go-grpc_opt=paths=source_relative \
  "${PROTO_FILE}"

echo ""
echo "✅ Stubs gerados com sucesso:"
echo "   service-a/calc_pb2.py"
echo "   service-a/calc_pb2_grpc.py"
echo "   benchmark/calc_pb2.py       (se pasta existir)"
echo "   benchmark/calc_pb2_grpc.py  (se pasta existir)"
echo "   gateway/calc_grpc/calc.pb.go"
echo "   gateway/calc_grpc/calc_grpc.pb.go"
