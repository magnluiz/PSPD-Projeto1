#!/bin/bash
cd "$(dirname "$0")"
python -m grpc_tools.protoc \
  -I proto \
  --python_out=. \
  --grpc_python_out=. \
  proto/demo.proto

echo "Arquivos gerados: demo_pb2.py e demo_pb2_grpc.py"