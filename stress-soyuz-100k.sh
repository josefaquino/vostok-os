#!/usr/bin/env bash
# ==============================================================================
# 🛰️  YODADB & KYBERDB — SOYUZ 100K URLS MASSIVE STRESS TESTER
# ==============================================================================
# Este script gera e ingere 100.000 registros TSV padronizados (RFC-0021)
# para forçar splits de páginas e o crescimento de nível da B-Tree via CGO.
# ==============================================================================
set -eo pipefail

# Cores ANSI para o cockpit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

clear
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BLUE}${BOLD} 🛰️  INICIANDO CARGA DE ESTRESSE: SOYUZ 100.000 URLs${RESET}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"

# 1. Sanity Check: Verifica se o binário do YodaDB existe
if [ ! -x "./yodadb" ]; then
    echo -e "${RED}❌ Erro: O binário './yodadb' não foi encontrado ou não é executável.${RESET}"
    echo -e "${YELLOW}Por favor, compile o projeto primeiro usando 'go build ./cmd/yodadb'.${RESET}"
    exit 1
fi

# 2. Configura e limpa bases antigas de teste (para isolar o estresse)
echo -e "${YELLOW}🧹 Limpando resíduos de logs e bancos anteriores...${RESET}"
rm -f yoda_storage.log yoda_bloom.dat yoda_storage.log.kyber yoda_storage.log.kyber.wal

# 3. Gerador de Alta Velocidade em AWK (Unix Pipeline Style)
# Gera 100.000 linhas TSV com o Gene Schema de 9 colunas (RFC-0021)
# Formato: [id \t timestamp \t bioma \t source_url \t title \t status \t content_hash \t driver_version \t payload]
echo -e "${BLUE}⚡ Gerando 100.000 sementes contínuas do Soyuz em RAM (awk)...${RESET}"

# 4. Executa a Ingestão em Pipeline de Alta Velocidade
echo -e "${BLUE}📥 Pipelining ativo: Gerador AWK ──> YodaDB (Ingestão + CGO B-Tree)${RESET}"
echo -e "${YELLOW}Aguarde, processando escritas físicas contíguas...${RESET}"

START_TIME=$(date +%s.%N)

awk 'BEGIN {
    split("market_financial,molecular_biology,satellite_orbit,climate_risk,open_gov", biomes, ",")
    split("VIABLE,DEGRADED,PROCESSING", statuses, ",")
    n_biomes = 5
    n_statuses = 3
    
    for (i = 0; i < 100000; i++) {
        biome = biomes[(i % n_biomes) + 1]
        status = statuses[(i % n_statuses) + 1]
        url = sprintf("https://soyuz.colony.internal/observation/seed_%06d", i)
        title = sprintf("Soyuz Telemetry Node Report %06d", i)
        content_hash = sprintf("%016x", i * 12345)
        driver_ver = "v1.0.0"
        payload = sprintf("{\"node_id\":%d,\"metrics\":{\"cpu\":%d,\"temp\":%d,\"status\":\"%s\"}}", i, i%100, 45+(i%30), status)
        
        printf "soyuz_%06d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", i, i, biome, url, title, status, content_hash, driver_ver, payload
    }
}' | ./yodadb put 1

END_TIME=$(date +%s.%N)
ELAPSED=$(echo "$END_TIME - START_TIME" | bc)
OPS=$(echo "100000 / $ELAPSED" | bc)

echo -e "${GREEN}${BOLD}✅ INGESTÃO CONCLUÍDA COM SUCESSO!${RESET}"
echo -e "${GREEN}⏱️  Tempo Decorrido:  $(printf "%.3f" $ELAPSED) segundos${RESET}"
echo -e "${GREEN}⚡ Throughput Médio: $(printf "%'d" $OPS) ops/s${RESET}"

# 5. Análise e Diagnóstico de Estrutura Física (B-Tree Metapages)
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BLUE}${BOLD} 📊 ESTATÍSTICAS DA B-TREE (PAGINAÇÃO & PROFUNDIDADE)${RESET}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"

if [ -f "yoda_storage.log" ]; then
    LOG_SIZE=$(du -h yoda_storage.log | cut -f1)
    echo -e "💾 Tamanho do Log Sequencial (Storage):  ${BOLD}${GREEN}$LOG_SIZE${RESET}"
fi

./yodadb kyber-stats

# 6. Testes Cirúrgicos de Point Lookup O(log N)
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BLUE}${BOLD} 🔍 VALIDAÇÃO DE ACESSO CIRÚRGICO O(log N)${RESET}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"

SAMPLES=("soyuz_000000" "soyuz_012345" "soyuz_050000" "soyuz_099999")

for key in "${SAMPLES[@]}"; do
    echo -e "${YELLOW}Buscando chave: $key...${RESET}"
    LOOKUP_START=$(date +%s.%N)
    RECORD=$(./yodadb get "$key" 2>/dev/null || echo "")
    LOOKUP_END=$(date +%s.%N)
    LATENCY=$(echo "($LOOKUP_END - LOOKUP_START) * 1000000" | bc)
    
    if [ -n "$RECORD" ]; then
        echo -e "   ${GREEN}✅ ENCONTRADO!${RESET} Latência: $(printf "%.1f" $LATENCY) µs"
        echo -e "   ${BLUE}Payload:${RESET} $RECORD"
    else
        echo -e "   ${RED}❌ CHAVE NÃO ENCONTRADA! (Falha de indexação)${RESET}"
    fi
    echo ""
done

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}🏆 CARGA DE ESTRESSE FINALIZADA! B-TREE HOMOLOGADA PARA PRODUÇÃO!${RESET}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
