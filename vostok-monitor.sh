#!/usr/bin/env bash
# ==============================================================================
# 🛰️  VOSTOK OS — MONITOR DE FILA E VELOCIDADE v1.0
# ==============================================================================
# Descrição: Utilitário em tempo real para acompanhar a esteira de dados
#            dos 20 workers e a taxa de persistência do SQLite WAL.
# Uso: bash vostok-monitor.sh [intervalo_em_segundos]
# ==============================================================================

CLR_RESET="\033[0m"
CLR_CYAN="\033[0;36m"
CLR_GREEN="\033[0;32m"
CLR_YELLOW="\033[0;33m"
CLR_RED="\033[0;31m"
CLR_WHITE="\033[1;37m"
CLR_GRAY="\033[90m"

INTERVAL="${1:-2}"
DB_PATH="/home/jose/Vostok/data/frontier.db"

# Se rodando fora do caminho padrão, tenta o local relativo
if [ ! -f "$DB_PATH" ]; then
    DB_PATH="./data/frontier.db"
fi

if [ ! -f "$DB_PATH" ]; then
    echo -e "${CLR_RED}[FALHA] Banco de dados frontier.db não localizado em $DB_PATH${CLR_RESET}" >&2
    exit 1
fi

# Limpa a tela para começar o dashboard
clear

# Variáveis para cálculo de taxa delta
PREV_DONE=0
FIRST_RUN=1

while true; do
    # Captura estatísticas do banco de forma rápida (WAL garante zero bloqueio)
    STATS=$(sqlite3 "$DB_PATH" << 'EOF'
    SELECT 
        COUNT(*),
        SUM(CASE WHEN status = 'QUEUED' THEN 1 ELSE 0 END),
        SUM(CASE WHEN status = 'PROCESSING' THEN 1 ELSE 0 END),
        SUM(CASE WHEN status = 'DONE' THEN 1 ELSE 0 END),
        SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END)
    FROM observations;
EOF
    )

    IFS='|' read -r TOTAL QUEUED PROCESSING DONE FAILED <<< "$STATS"

    # Tratamento de valores vazios/nulos
    TOTAL="${TOTAL:-0}"
    QUEUED="${QUEUED:-0}"
    PROCESSING="${PROCESSING:-0}"
    DONE="${DONE:-0}"
    FAILED="${FAILED:-0}"

    # Cálculo da taxa delta de processamento
    if [ "$FIRST_RUN" -eq 1 ]; then
        RATE="0.0"
        FIRST_RUN=0
    else
        DIFF=$((DONE - PREV_DONE))
        RATE=$(awk -v diff="$DIFF" -v interval="$INTERVAL" 'BEGIN { printf "%.2f", (diff/interval)*60 }')
    fi
    PREV_DONE="$DONE"

    # Desenha o painel tático de telemetria
    echo -e "${CLR_CYAN}==============================================================================${CLR_RESET}"
    echo -e "${CLR_WHITE}🛰️  VOSTOK OS — MONITOR ATIVO DE TELEMETRIA EM TEMPO REAL${CLR_RESET}"
    echo -e "${CLR_CYAN}==============================================================================${CLR_RESET}"
    echo -e "${CLR_GRAY}Banco de Dados : ${CLR_WHITE}$DB_PATH${CLR_RESET}"
    echo -e "${CLR_GRAY}Frequência     : ${CLR_WHITE}Atualizando a cada ${INTERVAL}s${CLR_RESET}"
    echo -e "${CLR_CYAN}------------------------------------------------------------------------------${CLR_RESET}"
    
    # Grid de Contadores
    printf "  ${CLR_GRAY}Total de Alvos  :${CLR_RESET} %-10s |  ${CLR_GREEN}Concluídos (DONE) :${CLR_RESET} %-10s\n" "$TOTAL" "$DONE"
    printf "  ${CLR_YELLOW}Na Fila (QUEUED):${CLR_RESET} %-10s |  ${CLR_RED}Falhas (FAILED)   :${CLR_RESET} %-10s\n" "$QUEUED" "$FAILED"
    printf "  ${CLR_CYAN}Processando     :${CLR_RESET} %-10s |  ${CLR_WHITE}Taxa de Ingestão  :${CLR_RESET} %s org/min\n" "$PROCESSING" "$RATE"
    echo -e "${CLR_CYAN}------------------------------------------------------------------------------${CLR_RESET}"

    # Desenha uma barra de progresso simples
    if [ "$TOTAL" -gt 0 ]; then
        PCT=$(( (DONE + FAILED) * 100 / TOTAL ))
        BAR_WIDTH=40
        FILLED=$(( PCT * BAR_WIDTH / 100 ))
        EMPTY=$(( BAR_WIDTH - FILLED ))
        
        printf "  ${CLR_GRAY}Progresso Geral :${CLR_RESET} ["
        printf "${CLR_GREEN}"
        for ((i=0; i<BAR_WIDTH; i++)); do
            if [ $i -lt $FILLED ]; then
                printf "■"
            else
                printf " "
            fi
        done
        printf "${CLR_RESET}"
        printf "] %d%%\n" "$PCT"
    fi

    echo -e "${CLR_CYAN}==============================================================================${CLR_RESET}"
    echo -e "${CLR_GRAY}Pressione [CTRL+C] para abortar a telemetria e retornar ao hangar.${CLR_RESET}"

    sleep "$INTERVAL"
    # Reposiciona o cursor no topo em vez de dar clear (evita flickering visual)
    printf "\033[16A"
done
