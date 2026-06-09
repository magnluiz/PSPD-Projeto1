import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import grpc
import demo_pb2, demo_pb2_grpc

def gerar_numeros():
    for n in [10, 20, 30, 40]:
        print(f"[client] enviando: {n}")
        yield demo_pb2.NumberRequest(value=n)

with grpc.insecure_channel("localhost:50051") as channel:
    stub = demo_pb2_grpc.DemoServiceStub(channel)
    resp = stub.SumNumbers(gerar_numeros())
    print(f"[client] soma total: {resp.total}")