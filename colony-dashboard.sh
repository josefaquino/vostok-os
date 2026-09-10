#!/bin/bash
# ==============================================================================
# 🚀 VOSTOK OS — COLONY DASHBOARD v1.1 (Optimized SRE Edition)
# ==============================================================================
# Descrição: Painel de linha de comando leve, ultra-rápido e compatível com 
#            SQLite WAL para monitorar a saúde da colônia e evolução da fila.
# Autor: Adaptado por R2-Kyber & Comandante Anakin
# ==============================================================================

# Cores ANSI para um terminal profissional e sofisticado
CLR_RESET="\033[0m"
CLR_TITLE="\033[1;36m"     # Ciano Negrito
CLR_BORDER="\033[0;34m"    # Azul
CLR_HIGHLIGHT="\033[1;32m" # Verde Negrito
CLR_WARN="\033[1;33m"      # Amarelo Negrito

# Determina o caminho do banco de dados de forma resiliente no Asus
DB_PATH="data/frontier.db"
if [ ! -f "$DB_PATH" ] && [ -f "/home/jose/Vostok/data/frontier.db" ]; then
    DB_PATH="/home/jose/Vostok/data/frontier.db"
fi

# Validação física do banco
if [ ! -f "$DB_PATH" ]; then
    echo -e "${CLR_WARN}[ERRO SRE] Banco de dados '$DB_PATH' não encontrado!${CLR_RESET}"
    echo "Certifique-se de que está executando o script de dentro da pasta ~/Vostok."
    exit 1
fi

while true; do
    clear
    echo -e "${CLR_TITLE}🚀 VOSTOK OS — COLONY DASHBOARD (SRE Live)${CLR_RESET}   🕒 $(date '+%H:%M:%S')"
    echo -e "${CLR_BORDER}══════════════════════════════════════════════════════════════════════${CLR_RESET}"
    
    # 1. Estatísticas Gerais (Com proteção contra divisão por zero e UNION ALL estruturado)
    echo -e "${CLR_HIGHLIGHT}📊 Distribuição de Células Larvais por Status:${CLR_RESET}"
    sqlite3 -header -column "$DB_PATH" "
    SELECT 
        status,
        COUNT(*) as total,
        ROUND(COUNT(*) * 100.0 / MAX((SELECT COUNT(*) FROM observations), 1), 1) || '%' as pct
    FROM observations 
    GROUP BY status
    UNION ALL
    SELECT 'TOTAL' as status, COUNT(*), '100.0%' FROM observations;
    "
    
    # 2. Taxa de processamento nos últimos 5 minutos (Com conversão robusta de timestamp RFC3339)
    echo ""
    echo -e "${CLR_HIGHLIGHT}📈 Taxa de Processamento Real (Últimos 5 Minutos):${CLR_RESET}"
    sqlite3 -header -column "$DB_PATH" "
    SELECT 
        COUNT(*) as processados,
        ROUND(COUNT(*) / 5.0, 1) || ' org/min' as taxa_media
    FROM observations 
    WHERE datetime(timestamp) > datetime('now', '-5 minutes')
    AND status IN ('DONE', 'FAILED', 'SKIPPED');
    "
    
    # 3. Top 10 domínios na fila (Usa parsing compatível com SQLite INSTR de 2 argumentos)
    echo ""
    echo -e "${CLR_HIGHLIGHT}🌐 Top 10 Domínios Semeados na Fila (QUEUED):${CLR_RESET}"
    sqlite3 -header -column "$DB_PATH" "
    SELECT 
        substr(replace(replace(source_url, 'https://', ''), 'http://', ''), 1, instr(replace(replace(source_url, 'https://', ''), 'http://', '') || '/', '/') - 1) as domain,
        COUNT(*) as queued
    FROM observations 
    WHERE status = 'QUEUED'
    GROUP BY domain
    ORDER BY queued DESC
    LIMIT 10;
    "
    
    echo -e "${CLR_BORDER}──────────────────────────────────────────────────────────────────────${CLR_RESET}"
    echo -e "Pressione ${CLR_WARN}[Ctrl+C]${CLR_RESET} para interromper o dashboard e retornar ao hangar."
    sleep 5
done
