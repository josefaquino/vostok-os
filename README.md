# YodaDB v10

Banco de dados local-first em C11 puro para agentes de IA.

## Componentes

- `yodadb` - CLI principal (put/get/stats/export)
- `yodadb-server` - Daemon para concorrência
- `yodadb-client` - Client para o daemon
- `yoda-research` - Análise incremental de código
- `yodadb-export` - Export para Parquet

## Uso

```bash
# Ingestão
cat data.tsv | ./yodadb put 1

# Busca
./yodadb get key_001

# Stats
./yodadb stats

# Export para Parquet
./yodadb-export yoda_storage.log output.parquet
cd ~/Vostok

cat > README.md << 'READMEEOF'
# YodaDB v10

Banco de dados local-first em C11 puro para agentes de IA.

## Componentes

- yodadb - CLI principal (put/get/stats/export)
- yodadb-server - Daemon para concorrência
- yodadb-client - Client para o daemon
- yoda-research - Análise incremental de código
- yodadb-export - Export para Parquet

## Fases Completas

- FASE 1-4: Fundação (B-tree, WAL, CLI)
- FASE 5: Integração YodaDB + KyberDB
- FASE 6: Validação de Produção
- FASE 7: Daemon Mode + GNU Parallel
- FASE 8: Yoda Research v5.1
- FASE 9: Parquet Export (Unix puro)
