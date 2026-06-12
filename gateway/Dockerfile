# ── Stage 1: generate Go stubs + build binary ────────────────────────────
FROM golang:1.25-alpine as builder

WORKDIR /build

# 1. FIX: Install protoc + version-locked Go plugins compatible with Go 1.24
RUN apk add --no-cache protobuf && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.33.0 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1

# 2. FIX: Copy go.mod/go.sum from the gateway subfolder
COPY gateway/go.mod gateway/go.sum ./
RUN go mod download

# 3. Generate stubs from proto (Context root prefix)
COPY proto/calc.proto /proto/calc.proto
RUN mkdir -p calc_grpc && \
    protoc \
      -I/proto \
      --go_out=calc_grpc \
      --go_opt=paths=source_relative \
      --go-grpc_out=calc_grpc \
      --go-grpc_opt=paths=source_relative \
      /proto/calc.proto

# 4. FIX: Copy ONLY gateway application files instead of the entire project root
COPY gateway/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o gateway .

# ── Stage 2: minimal runtime image ───────────────────────────────────────
FROM gcr.io/distroless/static-debian12

WORKDIR /app
COPY --from=builder /build/gateway .

EXPOSE 8080

ENTRYPOINT ["/app/gateway"]
