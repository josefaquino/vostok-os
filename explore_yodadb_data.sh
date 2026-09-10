#!/bin/bash
# explore_yodadb_data.sh - Script interativo para explorar dados ingeridos

set -euo pipefail

YODADB="./yodadb"
DATA_DIR="${HOME}/Sputnik/data"

echo "═══════════════════════════════════════════════════════════════"
echo "       🛰️  EXPLORANDO DADOS DO YODADB                         "
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Total de registros: $($YODADB stream 0 | wc -l)"
echo ""

# Funções de exploração
explore_by_source() {
    echo ""
    echo "📋 CONTAGEM POR FONTE (primeiras palavras do payload):"
    $YODADB stream 0 | awk -F'\t' '{print $5}' | head -1000 | \
        awk '{count[$1]++} END {for (word in count) print word, count[word]}' | \
        sort -rn | head -20
}

explore_sample() {
    echo ""
    echo "📋 AMOSTRA DE REGISTROS (10 primeiros):"
    $YODADB stream 0 | head -10 | column -t -s $'\t'
}

explore_airdata() {
    echo ""
    echo "✈️  DADOS DE DRONE (airdata):"
    $YODADB stream 0 | grep -i "Motors_Started" | head -5
    echo ""
    echo "Total de registros de drone: $($YODADB stream 0 | grep -i "Motors_Started" | wc -l)"
}

explore_spatial() {
    echo ""
    echo "🛰️  DADOS ESPACIAIS (NISAR/Spatial):"
    $YODADB stream 0 | grep -E "NISAR|spatial|granule" | head -5
    echo ""
    echo "Total de registros espaciais: $($YODADB stream 0 | grep -E "NISAR|spatial|granule" | wc -l)"
}

explore_benchmark() {
    echo ""
    echo "📊 DADOS DE BENCHMARK:"
    $YODADB stream 0 | grep -i "benchmark" | head -5
    echo ""
    echo "Total de registros de benchmark: $($YODADB stream 0 | grep -i "benchmark" | wc -l)"
}

explore_by_date() {
    echo ""
    echo "📅 DISTRIBUIÇÃO POR DATA (últimos 30 dias):"
    $YODADB stream 0 | awk -F'\t' '{print $2}' | cut -d'T' -f1 | sort | uniq -c | tail -20
}

explore_geographic() {
    echo ""
    echo "🌍 COORDENADAS GEOGRÁFICAS (amostra):"
    $YODADB stream 0 | grep -E "latitude|longitude" | head -5
}

explore_health_scores() {
    echo ""
    echo "❤️ DISTRIBUIÇÃO DE HEALTH SCORES:"
    $YODADB stream 0 | awk -F'\t' '{print $4}' | sort | uniq -c
}

# Menu interativo
while true; do
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "🔍 MENU DE EXPLORAÇÃO"
    echo "═══════════════════════════════════════════════════════════════"
    echo "1. Amostra geral de registros"
    echo "2. Contagem por fonte"
    echo "3. Dados de drone (airdata)"
    echo "4. Dados espaciais (NISAR)"
    echo "5. Dados de benchmark"
    echo "6. Distribuição por data"
    echo "7. Coordenadas geográficas"
    echo "8. Distribuição de health scores"
    echo "9. Exportar dados para CSV"
    echo "0. Sair"
    echo ""
    read -p "Escolha uma opção: " choice

    case $choice in
        1) explore_sample ;;
        2) explore_by_source ;;
        3) explore_airdata ;;
        4) explore_spatial ;;
        5) explore_benchmark ;;
        6) explore_by_date ;;
        7) explore_geographic ;;
        8) explore_health_scores ;;
        9) 
            echo ""
            read -p "Nome do arquivo de saída (ex: export.csv): " outfile
            $YODADB stream 0 > "$outfile"
            echo "✅ Exportado para $outfile ($(wc -l < $outfile) registros)"
            ;;
        0) echo "Saindo..."; break ;;
        *) echo "Opção inválida" ;;
    esac
done
