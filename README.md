
## Épico 1 — Tipos de comunicação gRPC ✅

Estudo prático dos quatro tipos de comunicação suportados pelo gRPC, implementados em Python com `demo.proto`.

### Pré-requisitos

```bash
pip install grpcio grpcio-tools
cd epico1-grpc && ./generate.sh
```

### Tipos implementados

| Tipo | Fluxo | Implementação | Quando usar |
|------|-------|---------------|-------------|
| Unary | 1 req → 1 resp | `unary/` | CRUD, autenticação, consultas simples |
| Server streaming | 1 req → N resps | `server_streaming/` | Feeds em tempo real, exportação progressiva |
| Client streaming | N reqs → 1 resp | `client_streaming/` | Upload em lote, acumulação de métricas |
| Bidirecional | N reqs ↔ N resps | `bidi_streaming/` | Chat, jogos multiplayer, pipelines contínuos |

```bash
python unary/server.py            # terminal 1
python unary/client.py            # terminal 2

python server_streaming/server.py # terminal 1
python server_streaming/client.py # terminal 2

python client_streaming/server.py # terminal 1
python client_streaming/client.py # terminal 2

python bidi_streaming/server.py   # terminal 1
python bidi_streaming/client.py   # terminal 2
```

---

## Épico 2 — Aplicação distribuída ✅

### Rodar localmente (sem Docker)

```bash
./generate.sh                          # gera stubs Python e Go
cd service-a && python server.py       # terminal 1
cd service-b && node server.js         # terminal 2
cd gateway   && go run main.go         # terminal 3
```

### Endpoints disponíveis

```bash
curl "http://localhost:8080/add?a=10&b=3"        # → {"result":13}
curl "http://localhost:8080/subtract?a=10&b=3"   # → {"result":7}
curl "http://localhost:8080/multiply?a=10&b=3"   # → {"result":30}
curl "http://localhost:8080/divide?a=10&b=3"     # → {"result":3.333...}
curl "http://localhost:8080/power?a=2&b=10"      # → {"result":1024}
curl "http://localhost:8080/sqrt?a=144"          # → {"result":12}
curl "http://localhost:8080/factorial?a=5"       # → {"result":120}
curl "http://localhost:8080/log?a=100&b=10"      # → {"result":2}
```

### Benchmark REST vs gRPC

O comparativo exigido pelo roteiro foi feito medindo a latência de cada operação por dois caminhos:

- **REST**: cliente → Gateway HTTP → gRPC interno → Service A ou B
- **gRPC direto**: cliente → Service A ou B diretamente via stub Python

```bash
cd benchmark && python benchmark.py --n 200 --warmup 20 --output results.md
```

**Resultados (200 chamadas, localhost):**

| Protocolo | Latência média | p95 |
|-----------|---------------|-----|
| gRPC direto | ~0.88 ms | ~1.1 ms |
| REST via gateway | ~1.20 ms | ~1.6 ms |

**Overhead médio do REST: +0.32 ms (+36%)**

O overhead é esperado e justificado: o gateway precisa parsear a query string HTTP, construir a mensagem Protobuf, fazer a chamada gRPC interna, aguardar a resposta e serializar o JSON de volta. Em localhost o delta é pequeno, mas em produção com serviços em nós distintos o gap cresce — gRPC usa HTTP/2 com multiplexing e binário, enquanto REST usa HTTP/1.1 com texto. O gateway REST se justifica como ponto de entrada para clientes externos (browsers, curl) que não falam gRPC nativamente.

---

## Épico 3 — Kubernetes / Minikube ✅

### Por que Kubernetes?

Kubernetes resolve o problema de orquestração: garantir que os containers estejam rodando, reiniciá-los se caírem, permitir escalonamento horizontal e isolar a rede interna dos serviços do acesso externo. Minikube simula um cluster completo em host único, ideal para desenvolvimento e para este experimento.

### Decisões de infraestrutura

- **Service A e B** usam `ClusterIP` — acessíveis apenas dentro do cluster, via DNS interno do Kubernetes (`service-a:50051`, `service-b:50052`). Isso reflete a arquitetura correta: microserviços não devem ser expostos diretamente ao mundo externo.
- **Gateway** usa `NodePort` — único ponto de entrada externo, expõe a porta 8080 no IP do Minikube.
- **`imagePullPolicy: Never`** — necessário para usar imagens buildadas localmente no daemon do Minikube, sem precisar de um registry externo.
- **Multi-stage build no gateway** — o estágio builder usa `golang:1.25-alpine` (com compilador, protoc, plugins Go), e o estágio final usa `distroless/static-debian12` (sem shell, sem libc, ~3MB). Isso reduz a superfície de ataque e o tamanho da imagem final.

### Pré-requisitos

```bash
chmod +x install_deps.sh && ./install_deps.sh
```

### Deploy

```bash
minikube start --driver=docker
./deploy.sh
```

`deploy.sh` automaticamente:
1. Aponta o Docker para o daemon interno do Minikube (`eval $(minikube docker-env)`)
2. Builda as 3 imagens com `--no-cache`
3. Aplica os manifests `k8s/*.yaml`
4. Aguarda os rollouts completarem
5. Imprime a URL do gateway

```bash
# Testar após o deploy
curl "$(minikube service gateway --url)/add?a=3&b=7"
curl "$(minikube service gateway --url)/factorial?a=5"
```

### Docker Compose (alternativa local sem Minikube)

```bash
docker compose up --build
curl "http://localhost:8080/sqrt?a=81"
```

### Parar o cluster

```bash
./stop.sh
```

`stop.sh` remove os workloads via `kubectl delete` antes de parar o Minikube, garantindo shutdown ordenado dos pods.

---

## Épico 4 — Relatório e entrega final ⏳

A ser iniciado.

---

## Referências

- gRPC: https://grpc.io/
- Protocol Buffers: https://protobuf.dev/
- Kubernetes: https://kubernetes.io/
- Minikube: https://minikube.sigs.k8s.io/docs/
- Cloud Native / CNCF: https://www.cncf.io/
- Go gRPC: https://grpc.io/docs/languages/go/
- Python gRPC: https://grpc.io/docs/languages/python/
- Node.js gRPC: https://grpc.io/docs/languages/node/
