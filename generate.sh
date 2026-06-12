#!/bin/bash
set -e
cd "$(dirname "$0")"

echo ">>> Python (service-a)..."
python -m grpc_tools.protoc \
  -I proto \
  --python_out=service-a \
  --grpc_python_out=service-a \
  proto/calc.proto

echo ">>> Go (gateway)..."






protoc-gen-go-grpc --version 2>/dev/null || go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

python -m grpc_tools.protoc \
  -I proto \
  --go_out=gateway \
  --go-grpc_out=gateway \
  proto/calc.proto

echo ">>> Node.js (service-b) — no generation needed (uses @grpc/proto-loader at runtime)"

echo ">>> Done."
