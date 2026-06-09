# PSPD — Projeto de Pesquisa: gRPC + Kubernetes

**Disciplina:** Programação para Sistemas Paralelos e Distribuídos  
**Instituição:** UnB / FCTE — Engenharia de Software  
**Professor:** Fernando W. Cruz

---

## Status geral do projeto

| Épico | Descrição | Status |
|---|---|---|
| Épico 1 | Estudo e testes com gRPC | ✅ Concluído |
| Épico 2 | Aplicação distribuída (P + A + B) | 🔧 Em andamento |
| Épico 3 | Infraestrutura Kubernetes / Minikube | ⏳ Não iniciado |
| Épico 4 | Relatório e entrega final | ⏳ Não iniciado |

---

## Estrutura do repositório

```
.
├── epico1-grpc/         ← exemplos dos 4 tipos de comunicação gRPC (concluído)
│   ├── proto/
│   │   └── demo.proto
│   ├── unary/
│   ├── server_streaming/
│   ├── client_streaming/
│   ├── bidi_streaming/
│   └── generate.sh
│
└── epico2-grpc/         ← aplicação distribuída calculadora (em andamento)
    ├── proto/
    │   └── calc.proto
    ├── service-a/       ← Python — operações básicas
    ├── service-b/       ← Node.js — operações avançadas
    ├── gateway/         ← Go — API REST + gRPC Stub
    └── generate.sh
```

---

## Épico 1 — Estudo e testes com gRPC ✅

O objetivo deste épico foi entender o framework gRPC na prática, implementando os quatro tipos de comunicação que ele suporta.

### Pré-requisitos

- Python 3.7+

```bash
pip install grpcio grpcio-tools
```

### Como gerar o código a partir do `.proto`

```bash
cd epico1-grpc
chmod +x generate.sh
./generate.sh
```

Isso gera `demo_pb2.py` e `demo_pb2_grpc.py` na raiz do épico 1, usados por todos os exemplos.

---

### O que foi implementado

#### Tipo 1 — Unary call

O cliente envia uma única requisição e recebe uma única resposta. É o padrão mais simples, equivalente a uma chamada HTTP comum.

```bash
python unary/server.py    # terminal 1
python unary/client.py    # terminal 2
```

Saída esperada:
```
[client] resposta: Olá, PSPD!
```

**Quando usar:** consultas simples, autenticação, operações de CRUD.

---

#### Tipo 2 — Server streaming

O cliente faz uma requisição e o servidor responde com um fluxo de mensagens ao longo do tempo.

```bash
python server_streaming/server.py    # terminal 1
python server_streaming/client.py    # terminal 2
```

Saída esperada:
```
[client] recebeu: 1
[client] recebeu: 2
...
[client] recebeu: 5
```

**Quando usar:** feeds em tempo real, exportação progressiva de dados, monitoramento de logs.

---

#### Tipo 3 — Client streaming

O cliente envia um fluxo de mensagens e o servidor responde com uma única resposta após receber tudo.

```bash
python client_streaming/server.py    # terminal 1
python client_streaming/client.py    # terminal 2
```

Saída esperada:
```
[client] enviando: 10
[client] enviando: 20
[client] enviando: 30
[client] enviando: 40
[client] soma total: 100
```

**Quando usar:** upload em chunks, envio em lote de métricas, acumulação de dados antes de processar.

---

#### Tipo 4 — Bidirecional streaming

Cliente e servidor trocam fluxos de mensagens simultaneamente sobre a mesma conexão.

```bash
python bidi_streaming/server.py    # terminal 1
python bidi_streaming/client.py    # terminal 2
```

Saída esperada:
```
[client] enviando: oi
[client] server respondeu: eco: oi
[client] enviando: tudo bem?
[client] server respondeu: eco: tudo bem?
```

**Quando usar:** chats em tempo real, jogos multiplayer, pipelines de processamento contínuo.

---

### Resumo dos tipos de comunicação

| Tipo | Fluxo | Melhor uso |
|---|---|---|
| Unary | 1 req → 1 resp | Operações simples e atômicas |
| Server streaming | 1 req → N resps | Dados volumosos ou progressivos |
| Client streaming | N reqs → 1 resp | Upload em lote ou acumulação |
| Bidirecional | N reqs ↔ N resps | Comunicação contínua e reativa |

---

## Épico 2 — Aplicação distribuída 🔧

Uma calculadora científica distribuída em três módulos independentes que se comunicam via gRPC.

| Módulo | Linguagem | Porta | Responsabilidade |
|---|---|---|---|
| Service A | Python | 50051 | Operações básicas: soma, subtração, multiplicação, divisão |
| Service B | Node.js | 50052 | Operações avançadas: potência, raiz, fatorial, logaritmo |
| Gateway P | Go | 8080 | API REST + gRPC Stub — interface HTTP para o browser |

O contrato entre os módulos está definido em `epico2-grpc/proto/calc.proto`.

> Esta etapa está em andamento. Os passos de implementação de cada módulo e o teste integrado serão documentados aqui conforme forem concluídos.

---

## Épico 3 — Kubernetes ⏳

Deploy da aplicação do Épico 2 em containers usando Minikube (cluster single-node). A ser iniciado após a conclusão do Épico 2.

---

## Referências

- gRPC: https://grpc.io/
- Protocol Buffers: https://protobuf.dev/
- Cloud Native / CNCF: https://www.cncf.io/
- Kubernetes: https://kubernetes.io/
- Minikube: https://minikube.sigs.k8s.io/docs/
