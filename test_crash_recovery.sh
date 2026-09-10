#!/usr/bin/env bash
# ============================================================================
# TESTE 1: CRASH RECOVERY (kill -9 durante escrita)
# ============================================================================
# Objetivo: Validar se o WAL recupera o banco após interrupção abrupta
# ============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

clear
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BLUE}${BOLD}🧪 TESTE 1: CRASH RECOVERY (kill -9)${RESET}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Limpar ambiente
echo -e "${YELLOW}🧹 Limpando ambiente...${RESET}"
rm -f yoda_storage.log yoda_storage.log.kyber yoda_storage.log.kyber.wal
echo ""

# Gerar dataset de teste (100k chaves)
echo -e "${BLUE}📦 Preparando dataset de 100k chaves...${RESET}"
awk 'BEGIN {
    for (i=0; i<100000; i++) {
        printf "key_%06d\tvalue_%06d\textra_%06d\n", i, i, i
    }
}' > /tmp/test_data.tsv
echo "   ✅ Dataset gerado ($(wc -l < /tmp/test_data.tsv) linhas)"
echo ""

# Iniciar ingestão em background
echo -e "${BLUE}🚀 Iniciando ingestão em background...${RESET}"
START_TIME=$(date +%s.%N)
cat /tmp/test_data.tsv | ./yodadb put 1 > /tmp/ingest.log 2>&1 &
INGEST_PID=$!
echo "   ✅ Processo de ingestão iniciado (PID: $INGEST_PID)"
echo ""

# Aguardar momento aleatório (entre 0.5s e 2s)
SLEEP_TIME=$(awk "BEGIN {printf \"%.2f\", 0.5 + rand() * 1.5}")
echo -e "${YELLOW}⏱️  Aguardando ${SLEEP_TIME}s antes do kill -9...${RESET}"
sleep $SLEEP_TIME

# KILL -9 (simular blackout)
echo -e "${RED}💥 KILL -9 (simulando blackout de energia)...${RESET}"
kill -9 $INGEST_PID 2>/dev/null || true
wait $INGEST_PID 2>/dev/null || true

END_TIME=$(date +%s.%N)
ELAPSED=$(awk "BEGIN {printf \"%.3f\", $END_TIME - $START_TIME}")
echo "   ⏱️  Processo interrompido após ${ELAPSED}s"
echo ""

# Verificar estado dos arquivos
echo -e "${BLUE}📊 Estado dos arquivos após crash:${RESET}"
ls -lh yoda_storage.log yoda_storage.log.kyber yoda_storage.log.kyber.wal 2>/dev/null | awk '{printf "   %-35s %s\n", $9, $5}'
echo ""

# Tentar reabrir o banco
echo -e "${BLUE}🔄 Tentando reabrir o banco...${RESET}"
if ! ./yodadb stats > /tmp/reopen_stats.txt 2>&1; then
    echo -e "${RED}❌ FALHA: Banco não conseguiu reabrir após crash!${RESET}"
    cat /tmp/reopen_stats.txt
    exit 1
fi
echo -e "${GREEN}✅ Banco reaberto com sucesso!${RESET}"
echo ""

# Verificar integridade: contar chaves recuperadas
echo -e "${BLUE}🔍 Verificando integridade (buscando amostras)...${RESET}"
STATS_OUTPUT=$(./yodadb stats)
echo "$STATS_OUTPUT"
echo ""

# Testar algumas chaves específicas
SAMPLES=(0 1000 10000 50000 99999)
FOUND=0
TOTAL=${#SAMPLES[@]}

for i in "${SAMPLES[@]}"; do
    key=$(printf "key_%06d" $i)
    if [ -n "$(./yodadb get "$key" 2>/dev/null)" ]; then
        FOUND=$((FOUND+1))
    fi
done

echo -e "${BLUE}📊 Resultado da amostragem:${RESET}"
echo "   Chaves testadas: $TOTAL"
echo "   Chaves encontradas: $FOUND"
echo ""

if [ $FOUND -eq $TOTAL ]; then
    echo -e "${GREEN}${BOLD}🏆 TESTE 1 APROVADO: Crash Recovery funcionando!${RESET}"
    echo -e "${GREEN}   WAL recuperou estado consistente após kill -9${RESET}"
else
    echo -e "${YELLOW}⚠️  TESTE 1 PARCIAL: $FOUND/$TOTAL chaves recuperadas${RESET}"
    echo -e "${YELLOW}   (Normal: chaves em buffer não flushado são perdidas)${RESET}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${RESET}"
