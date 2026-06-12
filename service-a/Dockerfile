FROM python:3.12-slim

WORKDIR /app

# Install dependencies first (layer cache)
COPY service-a/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy proto and generate stubs at build time
COPY proto/calc.proto /proto/calc.proto
RUN python -m grpc_tools.protoc \
      -I/proto \
      --python_out=. \
      --grpc_python_out=. \
      /proto/calc.proto

# Copy application
COPY service-a/server.py .

EXPOSE 50051

CMD ["python", "server.py"]
