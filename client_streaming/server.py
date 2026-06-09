import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import grpc
from concurrent import futures
import demo_pb2, demo_pb2_grpc

class DemoService(demo_pb2_grpc.DemoServiceServicer):
    def SumNumbers(self, request_iterator, context):
        total = 0
        for req in request_iterator:
            print(f"[server] recebeu: {req.value}")
            total += req.value
        return demo_pb2.SumReply(total=total)

server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))
demo_pb2_grpc.add_DemoServiceServicer_to_server(DemoService(), server)
server.add_insecure_port("[::]:50051")
server.start()
print("[server] rodando na porta 50051...")
server.wait_for_termination()