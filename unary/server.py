import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import grpc
from concurrent import futures
import demo_pb2, demo_pb2_grpc

class DemoService(demo_pb2_grpc.DemoServiceServicer):
    def SayHello(self, request, context):
        print(f"[server] recebeu: {request.name}")
        return demo_pb2.HelloReply(message=f"Olá, {request.name}!")

server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))
demo_pb2_grpc.add_DemoServiceServicer_to_server(DemoService(), server)
server.add_insecure_port("[::]:50051")
server.start()
print("[server] rodando na porta 50051...")
server.wait_for_termination()