# Benchmark — Épico 2: REST vs gRPC

Cada operação foi medida com **200 chamadas** (após warmup de 20 chamadas descartadas).
Latências em **milissegundos**.

## REST (via Gateway Go :8080)

| Operação  | Mín | Máx | Média | Mediana | p95 | Desvio |
|-----------|-----|-----|-------|---------|-----|--------|
| `add       ` | 0.834 | 1.974 | 1.018 | 0.976 | 1.253 | 0.158 |
| `subtract  ` | 0.903 | 3.182 | 1.295 | 1.265 | 1.894 | 0.308 |
| `multiply  ` | 0.879 | 1.906 | 1.191 | 1.198 | 1.382 | 0.153 |
| `divide    ` | 0.835 | 2.793 | 1.234 | 1.201 | 1.618 | 0.238 |
| `power     ` | 1.089 | 2.104 | 1.388 | 1.351 | 1.761 | 0.181 |
| `sqrt      ` | 1.052 | 1.93 | 1.214 | 1.176 | 1.553 | 0.15 |
| `factorial ` | 0.947 | 2.254 | 1.18 | 1.131 | 1.613 | 0.202 |
| `log       ` | 0.912 | 1.665 | 1.092 | 1.056 | 1.307 | 0.113 |

## gRPC direto (Service A :50051 / Service B :50052)

| Operação  | Mín | Máx | Média | Mediana | p95 | Desvio |
|-----------|-----|-----|-------|---------|-----|--------|
| `add       ` | 0.461 | 1.316 | 0.916 | 1.002 | 1.169 | 0.211 |
| `subtract  ` | 0.389 | 1.349 | 0.94 | 1.01 | 1.195 | 0.218 |
| `multiply  ` | 0.334 | 1.236 | 0.847 | 0.988 | 1.154 | 0.282 |
| `divide    ` | 0.494 | 1.425 | 0.862 | 0.849 | 1.141 | 0.167 |
| `power     ` | 0.585 | 2.118 | 0.96 | 0.896 | 1.584 | 0.258 |
| `sqrt      ` | 0.586 | 1.696 | 0.824 | 0.797 | 1.1 | 0.188 |
| `factorial ` | 0.6 | 1.864 | 0.941 | 0.804 | 1.576 | 0.302 |
| `log       ` | 0.482 | 1.833 | 0.772 | 0.67 | 1.383 | 0.253 |

## Comparação — overhead do REST vs gRPC (média, ms)

| Operação  | REST (ms) | gRPC (ms) | Overhead REST | gRPC mais rápido? |
|-----------|-----------|-----------|---------------|-------------------|
| `add       ` | 1.018 | 0.916 | +0.102 ms (+11.1%) | ✅ sim |
| `subtract  ` | 1.295 | 0.94 | +0.355 ms (+37.8%) | ✅ sim |
| `multiply  ` | 1.191 | 0.847 | +0.344 ms (+40.6%) | ✅ sim |
| `divide    ` | 1.234 | 0.862 | +0.372 ms (+43.2%) | ✅ sim |
| `power     ` | 1.388 | 0.96 | +0.428 ms (+44.6%) | ✅ sim |
| `sqrt      ` | 1.214 | 0.824 | +0.39 ms (+47.3%) | ✅ sim |
| `factorial ` | 1.18 | 0.941 | +0.239 ms (+25.4%) | ✅ sim |
| `log       ` | 1.092 | 0.772 | +0.32 ms (+41.5%) | ✅ sim |

## Conclusão

Em média, o gRPC direto apresentou latência de **0.883 ms** contra **1.202 ms** via REST, representando um overhead médio de **+0.319 ms** (+36.1%) ao passar pelo gateway HTTP.

O overhead é esperado: o gateway precisa parsear a query string, montar a requisição gRPC internamente, aguardar a resposta e serializar o JSON. Para sistemas onde a latência é crítica, comunicação gRPC direta entre serviços é preferível; o gateway REST é justificado apenas como ponto de entrada para clientes externos (browser, curl, etc.).