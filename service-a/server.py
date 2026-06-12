import grpc
from concurrent import futures
import calc_pb2
import calc_pb2_grpc
import math

class BasicService(calc_pb2_grpc.BasicServiceServicer):
    def Add(self, request, context):
        return calc_pb2.CalcReply(result=request.a + request.b)

    def Subtract(self, request, context):
        return calc_pb2.CalcReply(result=request.a - request.b)

    def Multiply(self, request, context):
        return calc_pb2.CalcReply(result=request.a * request.b)

    def Divide(self, request, context):
        if request.b == 0:
            return calc_pb2.CalcReply(error="division by zero")
        return calc_pb2.CalcReply(result=request.a / request.b)

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))
    calc_pb2_grpc.add_BasicServiceServicer_to_server(BasicService(), server)
    server.add_insecure_port("[::]:50051")
    server.start()
    print("[service-a] running on port 50051")
    server.wait_for_termination()

if __name__ == "__main__":
    serve()
