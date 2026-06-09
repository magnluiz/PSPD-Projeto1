import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import grpc
import demo_pb2, demo_pb2_grpc

def mensagens():
    for texto in ["oi", "tudo bem?", "até mais"]:
        print(f"[client] enviando: {texto}")
        yield demo_pb2.ChatMessage(user="aluno", text=texto)

with grpc.insecure_channel("localhost:50051") as channel:
    stub = demo_pb2_grpc.DemoServiceStub(channel)
    for resp in stub.Chat(mensagens()):
        print(f"[client] server respondeu: {resp.text}")