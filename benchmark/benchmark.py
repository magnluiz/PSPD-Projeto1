#!/usr/bin/env python3
"""
PSPD — Épico 2 Benchmark
Compara latência REST (via Gateway Go :8080) vs gRPC direto (Service A :50051 / Service B :50052)

Pré-requisito: os três serviços devem estar rodando:
    cd service-a && python server.py       # terminal 1
    cd service-b && node server.js         # terminal 2
    cd gateway   && go run main.go         # terminal 3

Uso:
    python benchmark.py [--n 200] [--warmup 20] [--output results.md]
"""

import argparse
import statistics
import time
import urllib.request
import json
import grpc
import sys

# Gerado por generate.sh (ou pelo benchmark em si, se rodado da mesma pasta)
try:
    import calc_pb2
    import calc_pb2_grpc
except ModuleNotFoundError:
    print("Erro: calc_pb2.py não encontrado. Rode este script a partir da pasta que contém os stubs gerados.")
    sys.exit(1)

# ── Configuração ────────────────────────────────────────────────────────────

GATEWAY_BASE = "http://localhost:8080"
SERVICE_A_ADDR = "localhost:50051"
SERVICE_B_ADDR = "localhost:50052"

OPERATIONS = [
    # (nome, endpoint_rest, tipo, args_grpc)
    # tipo: "basic_binary", "basic_unary", "advanced_binary", "advanced_unary"
    ("add",      "/add?a=10&b=3",       "basic_binary",    dict(a=10, b=3)),
    ("subtract", "/subtract?a=10&b=3",  "basic_binary",    dict(a=10, b=3)),
    ("multiply", "/multiply?a=10&b=3",  "basic_binary",    dict(a=10, b=3)),
    ("divide",   "/divide?a=10&b=3",    "basic_binary",    dict(a=10, b=3)),
    ("power",    "/power?a=2&b=10",     "advanced_binary", dict(a=2,  b=10)),
    ("sqrt",     "/sqrt?a=144",         "advanced_unary",  dict(a=144)),
    ("factorial","/factorial?a=10",     "advanced_unary",  dict(a=10)),
    ("log",      "/log?a=100&b=10",     "advanced_binary", dict(a=100, b=10)),
]

# ── Helpers ─────────────────────────────────────────────────────────────────

def measure_rest(url: str, n: int) -> list[float]:
    """Retorna lista de latências em ms para N chamadas REST."""
    latencies = []
    for _ in range(n):
        t0 = time.perf_counter()
        with urllib.request.urlopen(url, timeout=5) as resp:
            resp.read()
        latencies.append((time.perf_counter() - t0) * 1000)
    return latencies


def measure_grpc_basic(stub_a, op_name: str, args: dict, n: int) -> list[float]:
    method_map = {
        "add":      stub_a.Add,
        "subtract": stub_a.Subtract,
        "multiply": stub_a.Multiply,
        "divide":   stub_a.Divide,
    }
    fn = method_map[op_name]
    req = calc_pb2.BinaryRequest(**args)
    latencies = []
    for _ in range(n):
        t0 = time.perf_counter()
        fn(req)
        latencies.append((time.perf_counter() - t0) * 1000)
    return latencies


def measure_grpc_advanced(stub_b, op_name: str, op_type: str, args: dict, n: int) -> list[float]:
    if op_type == "advanced_binary":
        method_map = {
            "power": stub_b.Power,
            "log":   stub_b.Log,
        }
        fn = method_map[op_name]
        req = calc_pb2.BinaryRequest(**args)
    else:  # advanced_unary
        method_map = {
            "sqrt":      stub_b.SquareRoot,
            "factorial": stub_b.Factorial,
        }
        fn = method_map[op_name]
        req = calc_pb2.UnaryRequest(**args)

    latencies = []
    for _ in range(n):
        t0 = time.perf_counter()
        fn(req)
        latencies.append((time.perf_counter() - t0) * 1000)
    return latencies


def summarize(latencies: list[float]) -> dict:
    return {
        "min":    round(min(latencies),    3),
        "max":    round(max(latencies),    3),
        "mean":   round(statistics.mean(latencies),   3),
        "median": round(statistics.median(latencies), 3),
        "p95":    round(sorted(latencies)[int(len(latencies) * 0.95)], 3),
        "stddev": round(statistics.stdev(latencies),  3),
    }


# ── Report ──────────────────────────────────────────────────────────────────

def render_markdown(results: list[dict]) -> str:
    lines = []
    lines.append("# Benchmark — Épico 2: REST vs gRPC")
    lines.append("")
    lines.append(f"Cada operação foi medida com **{results[0]['n']} chamadas** (após warmup de {results[0]['warmup']} chamadas descartadas).")
    lines.append("Latências em **milissegundos**.")
    lines.append("")

    # REST table
    lines.append("## REST (via Gateway Go :8080)")
    lines.append("")
    lines.append("| Operação  | Mín | Máx | Média | Mediana | p95 | Desvio |")
    lines.append("|-----------|-----|-----|-------|---------|-----|--------|")
    for r in results:
        s = r["rest"]
        lines.append(f"| `{r['op']:<10}` | {s['min']} | {s['max']} | {s['mean']} | {s['median']} | {s['p95']} | {s['stddev']} |")

    lines.append("")

    # gRPC table
    lines.append("## gRPC direto (Service A :50051 / Service B :50052)")
    lines.append("")
    lines.append("| Operação  | Mín | Máx | Média | Mediana | p95 | Desvio |")
    lines.append("|-----------|-----|-----|-------|---------|-----|--------|")
    for r in results:
        s = r["grpc"]
        lines.append(f"| `{r['op']:<10}` | {s['min']} | {s['max']} | {s['mean']} | {s['median']} | {s['p95']} | {s['stddev']} |")

    lines.append("")

    # Comparison table
    lines.append("## Comparação — overhead do REST vs gRPC (média, ms)")
    lines.append("")
    lines.append("| Operação  | REST (ms) | gRPC (ms) | Overhead REST | gRPC mais rápido? |")
    lines.append("|-----------|-----------|-----------|---------------|-------------------|")
    for r in results:
        rm = r["rest"]["mean"]
        gm = r["grpc"]["mean"]
        overhead = round(rm - gm, 3)
        pct = round((overhead / gm) * 100, 1) if gm > 0 else 0
        faster = "✅ sim" if gm < rm else "❌ não"
        lines.append(f"| `{r['op']:<10}` | {rm} | {gm} | +{overhead} ms (+{pct}%) | {faster} |")

    lines.append("")
    lines.append("## Conclusão")
    lines.append("")
    avg_rest = statistics.mean(r["rest"]["mean"] for r in results)
    avg_grpc = statistics.mean(r["grpc"]["mean"] for r in results)
    overhead_avg = round(avg_rest - avg_grpc, 3)
    lines.append(
        f"Em média, o gRPC direto apresentou latência de **{avg_grpc:.3f} ms** "
        f"contra **{avg_rest:.3f} ms** via REST, "
        f"representando um overhead médio de **+{overhead_avg:.3f} ms** "
        f"(+{round((overhead_avg/avg_grpc)*100,1)}%) ao passar pelo gateway HTTP."
    )
    lines.append("")
    lines.append(
        "O overhead é esperado: o gateway precisa parsear a query string, montar "
        "a requisição gRPC internamente, aguardar a resposta e serializar o JSON. "
        "Para sistemas onde a latência é crítica, comunicação gRPC direta entre "
        "serviços é preferível; o gateway REST é justificado apenas como ponto de "
        "entrada para clientes externos (browser, curl, etc.)."
    )
    return "\n".join(lines)


# ── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Benchmark REST vs gRPC — PSPD Épico 2")
    parser.add_argument("--n",       type=int, default=200,          help="Número de chamadas por operação (default: 200)")
    parser.add_argument("--warmup",  type=int, default=20,           help="Chamadas de warmup descartadas (default: 20)")
    parser.add_argument("--output",  type=str, default="results.md", help="Arquivo de saída Markdown (default: results.md)")
    args = parser.parse_args()

    print(f"Benchmark PSPD — {args.n} chamadas + {args.warmup} warmup por operação\n")

    # Abre canais gRPC (um único canal reutilizado — equivalente ao gateway)
    chan_a = grpc.insecure_channel(SERVICE_A_ADDR)
    chan_b = grpc.insecure_channel(SERVICE_B_ADDR)
    stub_a = calc_pb2_grpc.BasicServiceStub(chan_a)
    stub_b = calc_pb2_grpc.AdvancedServiceStub(chan_b)

    results = []

    for op_name, endpoint, op_type, grpc_args in OPERATIONS:
        url = GATEWAY_BASE + endpoint
        print(f"  {op_name:<12}", end="", flush=True)

        # ── warmup (descartado) ──
        try:
            measure_rest(url, args.warmup)
        except Exception as e:
            print(f"\n  ⚠️  Gateway não responde em {url}: {e}")
            print("     Verifique se os 3 serviços estão rodando e tente novamente.")
            sys.exit(1)

        if op_type == "basic_binary":
            measure_grpc_basic(stub_a, op_name, grpc_args, args.warmup)
        else:
            measure_grpc_advanced(stub_b, op_name, op_type, grpc_args, args.warmup)

        # ── medição real ──
        rest_lat = measure_rest(url, args.n)

        if op_type == "basic_binary":
            grpc_lat = measure_grpc_basic(stub_a, op_name, grpc_args, args.n)
        else:
            grpc_lat = measure_grpc_advanced(stub_b, op_name, op_type, grpc_args, args.n)

        rest_s = summarize(rest_lat)
        grpc_s = summarize(grpc_lat)

        print(f"REST p50={rest_s['median']}ms   gRPC p50={grpc_s['median']}ms")

        results.append({
            "op":     op_name,
            "n":      args.n,
            "warmup": args.warmup,
            "rest":   rest_s,
            "grpc":   grpc_s,
        })

    chan_a.close()
    chan_b.close()

    md = render_markdown(results)
    with open(args.output, "w") as f:
        f.write(md)

    print(f"\nResultados salvos em → {args.output}")
    print("\n" + md)


if __name__ == "__main__":
    main()
