import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import grpc, time
from concurrent import futures
import demo_pb2, demo_pb2_grpc

class DemoService(demo_pb2_grpc.DemoServiceServicer):
    def ListNumbers(self, request, context):
        print(f"[server] streaming de {request.start} até {request.end}")
        for i in range(request.start, request.end + 1):
            time.sleep(0.3)
            yield demo_pb2.NumberReply(value=i)

server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))
demo_pb2_grpc.add_DemoServiceServicer_to_server(DemoService(), server)
server.add_insecure_port("[::]:50051")
server.start()
print("[server] rodando na porta 50051...")
server.wait_for_termination()