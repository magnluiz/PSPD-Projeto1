import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import grpc
import demo_pb2, demo_pb2_grpc

with grpc.insecure_channel("localhost:50051") as channel:
    stub = demo_pb2_grpc.DemoServiceStub(channel)
    for resp in stub.ListNumbers(demo_pb2.RangeRequest(start=1, end=5)):
        print(f"[client] recebeu: {resp.value}")