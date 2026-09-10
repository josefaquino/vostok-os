# FASE 8: Yoda Research - Analise Incremental de Codigo

## Status: PROOF-OF-CONCEPT VALIDADO (v5.1)

## Conceito

Cache incremental de analise de codigo usando YodaDB:
- Primeira execucao: escaneia tudo, armazena hash por arquivo
- Segunda execucao: pula arquivos inalterados (cache hit)
- Sistema de exclusao via .yoda-ignore (similar ao .gitignore)

## Resultados do Benchmark (v5.1 final)

| Metrica | v3 (sem ignore) | v5.1 (final) | Melhoria |
|---------|-----------------|--------------|----------|
| Arquivos | 3.826 | 65 | -98.3% |
| Scan 1 | 38.297s | 0.739s | -98.1% |
| Scan 2 | 12.045s | 0.379s | -96.9% |
| Speedup | 3.2x | 1.9x | - |
| Achados | 1.498 | 5 | -99.7% |

## Arquitetura

yoda-research scan <dir>
  ├─ .yoda-ignore: lista de diretorios/arquivos a excluir
  ├─ find: encontra arquivos fonte (*.c, *.h, *.py, etc)
  ├─ grep -vE: filtra usando regex construida do .yoda-ignore
  ├─ sha256sum: calcula hash de cada arquivo
  ├─ cache local (bash assoc array): verifica se hash ja foi processado
  ├─ ripgrep: escaneia padroes de seguranca (fixed-strings)
  ├─ batch put: armazena hashes no YodaDB (1 conexao socket)
  └─ report: gera TSV com achados

## .yoda-ignore

Sistema de exclusao similar ao .gitignore:
- Diretorios: db-5.3.28, venv_yodadb, node_modules, __pycache__, .git
- Arquivos: *.o, *.so, *.pyc, *.min.js, *.min.css

Regex construida dinamicamente:
- `db-5.3.28` → `db-5\.3\.28`
- `*.o` → `[^/]*\.o` (qualquer caractere exceto /, seguido de .o)

## Padroes de Seguranca

13 padroes simples (fixed-strings):
- strcpy(, strcat(, sprintf(, gets(
- system(, popen(, exec(, eval(
- password=, passwd=, secret=, api_key=, token=

## Limitacoes Conhecidas

1. Speedup 1.9x: ainda calcula sha256sum de todos os arquivos no Scan 2
   → Solucao futura: usar timestamps (find -newer) para pular sem hash
2. Falsos positivos: sprintf() em shell scripts nao e vulnerabilidade
   → Solucao futura: filtros mais inteligentes por tipo de arquivo

## Proximos Passos

FASE 9: Parquet Export (analitico com DuckDB/Polars)
FASE 10: Snappy Compression (reducao de storage)

## Integracao com Mantis (Google)

Este PoC demonstra o conceito central do Mantis:
- Reduzir trabalho repetido com cache
- Analisar apenas o que mudou
- Armazenar contexto de forma persistente

YodaDB como camada de cache para agentes de IA.
