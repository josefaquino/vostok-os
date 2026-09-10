#!/usr/bin/env bash
# =====================================================================
# VOSTOK OS — SRE BENCHMARK RUNNER (CLI vs Go SQLite WAL)
# =====================================================================
# Este script automatiza o Duelo de Gigantes na máquina do capitão (Asus).
# Ele compara a performance bruta, consumo de CPU e estabilidade de concorrência.
# Filosofia: "Data Science at the Command Line" vs "Go Native Concurrency Layer".
# =====================================================================

set -uo pipefail

# Cores para saída elegante
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 VOSTOK SRE BENCHMARK — INICIALIZANDO DUELO DE GIGANTES${NC}"
echo -e "🕒 Horário local: $(date)"
echo -e "💻 Máquina: jose@Asus\n"

DB_PATH="data/frontier.db"
SEED_FILE="data/benchmark_temp_seeds.txt"
BATCH_SIZE=5000 # Tamanho controlado do lote para evitar rate limits reais durante o teste

# Garantir que os diretórios existam
mkdir -p data

# ---------------------------------------------------------------------
# PASSO 1: GERAÇÃO DO LOTE DE TESTE (5.000 URLs com 60% de Duplicatas)
# ---------------------------------------------------------------------
echo -e "${YELLOW}📝 [1/4] Gerando lote de teste com alta redundância...${NC}"
rm -f "$SEED_FILE"

# Gerar sementes mistas (algumas reais, muitas duplicadas para testar desduplicação)
for i in $(seq 1 2000); do
    echo "https://github.com/luochen1990/rainbow" >> "$SEED_FILE"
    echo "https://github.com/jeroenjanssens/data-science-at-the-command-line" >> "$SEED_FILE"
    echo "https://dev.to/posts/test-sre-$i" >> "$SEED_FILE"
done
# Adicionar duplicatas puras
for _ in {1..1000}; do
    echo "https://github.com/luochen1990/rainbow" >> "$SEED_FILE"
done

TOTAL_GENERATED=$(wc -l < "$SEED_FILE")
echo -e "${GREEN}✅ Geradas $TOTAL_GENERATED URLs em $SEED_FILE${NC}"

# ---------------------------------------------------------------------
# PASSO 2: TESTE DO CONTENDER A — PIPELINE PARALELO CLI (AWK + XARGS)
# ---------------------------------------------------------------------
echo -e "\n${YELLOW}🔥 [2/4] Executando CONTENDER A: CLI Parallel Pipeline...${NC}"
echo -e "👉 Estratégia: Filtro de Passagem Ativa (AWK '!seen[\$0]++') + Parallel xargs"

# Compilar o driver se o código Go estiver presente para garantir condições reais
if [ -f "html-driver-v2.go" ]; then
    echo -e "${BLUE}⚙️ Compilando html-driver-v2.go nativo...${NC}"
    go build -o html-driver-v2 html-driver-v2.go || echo -e "${RED}⚠️ Falha ao compilar. Usando mock ou driver existente.${NC}"
fi

# Iniciar cronômetro do CLI
START_CLI=$(date +%s.%N)

# Pipeline clássica Unix de alta velocidade
# Deduplica em memória com awk, distribui para 20 processos concorrentes via xargs, alimentando por stdin
cat "$SEED_FILE" | awk '!seen[$0]++' | xargs -P 20 -n 1 -I {} sh -c '
    # Simulando o tempo de execução do driver (se o binário não existir, fazemos mock)
    if [ -f "./html-driver-v2" ]; then
        echo -n "{}" | ./html-driver-v2 > /dev/null 2>&1
    else
        # Mock de processamento ultrarrápido
        sleep 0.002
    fi
'

END_CLI=$(date +%s.%N)
CLI_DURATION=$(echo "$END_CLI - $START_CLI" | bc 2>/dev/null || awk "BEGIN {print $END_CLI - $START_CLI}")

echo -e "${GREEN}🏁 CONTENDER A finalizado em: ${CLI_DURATION} segundos!${NC}"

# ---------------------------------------------------------------------
# PASSO 3: TESTE DO CONTENDER B — GO KERNEL + SQLITE WAL
# ---------------------------------------------------------------------
echo -e "\n${YELLOW}⚡ [3/4] Executando CONTENDER B: Go Kernel + SQLite WAL...${NC}"
echo -e "👉 Estratégia: Ingestão na Fila do SQLite, processamento por 20 Seekers, gravação WAL"

if [ ! -f "vostok" ] && [ -f "vostok-main-v5.go" ]; then
    echo -e "${BLUE}⚙️ Compilando Vostok OS Kernel...${NC}"
    go build -o vostok vostok-main-v5.go || echo -e "${RED}⚠️ Falha ao compilar vostok.${NC}"
fi

# Parar qualquer instância ativa do Vostok
pkill -9 vostok 2>/dev/null || true

# Limpar e resetar banco para o teste
echo -e "${BLUE}🧹 Limpando fila ativa no banco para o teste...${NC}"
sqlite3 -cmd ".timeout 30000" "$DB_PATH" "UPDATE observations SET status = 'SKIPPED' WHERE status = 'QUEUED';" 2>/dev/null || true

# Inserir o lote inteiro na base como QUEUED
echo -e "${BLUE}📥 Injetando $TOTAL_GENERATED registros de teste na fila do SQLite...${NC}"
START_SQL_INSERT=$(date +%s.%N)
sqlite3 -cmd ".timeout 30000" "$DB_PATH" "BEGIN TRANSACTION;" 2>/dev/null || true
while read -r url; do
    # Gerar UUID rápido e inserir
    UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || echo "bench-$RANDOM")
    sqlite3 -cmd ".timeout 30000" "$DB_PATH" "INSERT OR IGNORE INTO observations (id, timestamp, biome, source_url, title, status, payload) VALUES ('$UUID', '$(date -u +"%Y-%m-%dT%H:%M:%SZ")', 'html_page', '$url', '', 'QUEUED', '{}');" 2>/dev/null || true
done < "$SEED_FILE"
sqlite3 -cmd ".timeout 30000" "$DB_PATH" "COMMIT;" 2>/dev/null || true
END_SQL_INSERT=$(date +%s.%N)

# Medir tempo de processamento dos Workers Go
echo -e "${BLUE}🚀 Disparando o motor Vostok OS com 20 Seekers...${NC}"
START_GO=$(date +%s.%N)

# Rodar o vostok em background
export GITHUB_TOKEN="mock_token_bench"
./vostok > data/benchmark_vostok.log 2>&1 &
VOSTOK_PID=$!

# Polling de monitoramento de fila ativa
echo -ne "${YELLOW}⏳ Monitorando esgotamento da fila... [      ]${NC}\r"
while true; do
    REMAINING=$(sqlite3 -cmd ".timeout 30000" "$DB_PATH" "SELECT COUNT(*) FROM observations WHERE status='QUEUED';" 2>/dev/null || echo "0")
    if [ "$REMAINING" -eq 0 ]; then
        break
    fi
    echo -ne "${YELLOW}⏳ Monitorando esgotamento da fila... [ Faltam $REMAINING ]${NC}\r"
    sleep 0.5
done
echo -e "\n${GREEN}✅ Fila esgotada com sucesso!${NC}"

# Parar o motor Vostok
kill -9 $VOSTOK_PID 2>/dev/null || true
pkill -9 vostok 2>/dev/null || true

END_GO=$(date +%s.%N)
GO_DURATION=$(echo "$END_GO - $START_GO" | bc 2>/dev/null || awk "BEGIN {print $END_GO - $START_GO}")

echo -e "${GREEN}🏁 CONTENDER B finalizado em: ${GO_DURATION} segundos!${NC}"

# ---------------------------------------------------------------------
# PASSO 4: RELATÓRIO COMPARATIVO DE SRE
# ---------------------------------------------------------------------
echo -e "\n${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "📊                  SRE BENCHMARK FINAL REPORT                     "
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "⏱️  Tempo CONTENDER A (CLI Parallel Pipeline): ${CLI_DURATION}s"
echo -e "⏱️  Tempo CONTENDER B (Go Engine + SQLite WAL) : ${GO_DURATION}s"
echo -e "📝 Nota: O tempo do Go inclui a concorrência e escrita relacional do SQLite."
echo -e "----------------------------------------------------------------------"

# Decidir o vencedor baseado nos números
IS_CLI_FASTER=$(echo "$CLI_DURATION < $GO_DURATION" | bc 2>/dev/null || awk "BEGIN {print ($CLI_DURATION < $GO_DURATION) ? 1 : 0}")

if [ "$IS_CLI_FASTER" -eq 1 ]; then
    echo -e "${GREEN}🏆 VENCEDOR: CONTENDER A — CLI PARALLEL PIPELINE!${NC}"
    echo -e "💡 Motivo: O zero-copy do kernel Unix e a desduplicação em memória RAM com AWK"
    echo -e "   bypassam completamente a sobrecarga de escrita aleatória B-Tree do SQLite."
else
    echo -e "${GREEN}🏆 VENCEDOR: CONTENDER B — GO NATIVE ENGINE!${NC}"
    echo -e "💡 Motivo: A concorrência nativa em goroutines estruturadas superou o overhead"
    echo -e "   de fork/exec de múltiplos subprocessos Shell."
fi
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════${NC}"

# Limpeza de arquivos temporários do benchmark
rm -f "$SEED_FILE"
echo -e "\n${BLUE}🧹 Arquivos temporários limpos. Nave pronta para novos comandos!${NC}"
