# CASE STUDY: Rush Integration no YodaDB

## Para: Jeroen Janssens
## De: Projeto Yoda Systems

## Contexto
YodaDB: banco local-first C11 (18KB). Precisavamos de analise estatistica sem Python.
Solucao: rush como camada opcional de Data Science.

## Arquitetura
Agentes IA -> yoda-shield (PII) -> yodadb put (C11)
                                      |
                                      +-> yodadb export -> Parquet -> DuckDB
                                      |
                                      +-> yoda-rush -> rush (R) -> Estatistica

## Casos de Uso

### 1. Estatisticas Descritivas
./yoda-rush stats

### 2. Deteccao de Outliers
./yoda-rush outliers payload_length

### 3. Filtro Estatistico
cat input | yoda-shield | rush 'filter(scale(x) < 3)' | yodadb put

## Comparacao rush vs DuckDB
- rush: sintaxe dplyr, ggplot2, analise ad-hoc
- DuckDB: performance, streaming, SQL universal
- Conclusao: complementares, nao concorrentes

## Licoes Aprendidas
1. rush para batch, nao streaming (overhead ~200ms)
2. Sanitizar ANTES de analise (privacy first)
3. Fallback gracioso para DuckDB se rush ausente

## Metricas
- Linhas de codigo: 20 (SQL) -> 3 (rush)
- Tempo prototipagem: 10min -> 2min
- Binary: 18KB (inalterado)

## Proximos Passos
- FASE 13: Read Mode (multi-reader)
- FASE 14: yoda-rush plot (ggplot2)
