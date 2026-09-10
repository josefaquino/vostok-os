#!/usr/bin/env bash
# ==============================================================================
# Yoda Systems - File Locator Tool (SRE Utility)
# This script searches for Force Shield, YodaDB, and KyberDB files on Debian.
# ==============================================================================

# Cores ANSI para saída estilizada
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=======================================================================${NC}"
echo -e "${GREEN}🛰️  R2-KYBER: LOCATOR DE COMPONENTES DO YODA SYSTEMS${NC}"
echo -e "${CYAN}=======================================================================${NC}"
echo ""

# Diretórios principais de busca (pode incluir caminhos reais do Asus Debian se aplicável)
SEARCH_DIRS=( "$HOME" "/workspace" "." )

# Lista de arquivos vitais da nossa arquitetura
FILES_TO_FIND=(
    # --- Force Shield Modules ---
    "sputnik-policy-masker.sh"
    "sputnik-policy-masker-v2.sh"
    "yoda-force-shield.sh"
    "vostok-shield-queue.sh"
    
    # --- YodaDB & KyberDB Core (C11 Puro & Go) ---
    "btree.c"
    "wal.c"
    "kyber_btree.h"
    "yodadb_cli.c"
    "test_btree_contract.c"
    "kyber.go"
    "yodadb.go"
    
    # --- Orquestradores Vostok ---
    "vostok-main.go"
    "vostok-workers.go"
    "Makefile.yodadb"
)

echo -e "${YELLOW}Iniciando varredura profunda pelo sistema...${NC}"
echo ""

FOUND_COUNT=0

for item in "${FILES_TO_FIND[@]}"; do
    echo -e "${BLUE}🔍 Buscando por: ${YELLOW}$item${NC}"
    FOUND_LOCATIONS=()
    
    # Varre cada diretório de busca definido
    for dir in "${SEARCH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            # Omitimos erros de permissão redirecionando o stderr
            while IFS= read -r path; do
                if [ -n "$path" ]; then
                    FOUND_LOCATIONS+=("$path")
                fi
            done < <(find "$dir" -type f -name "$item" 2>/dev/null)
        fi
    done
    
    # Exibe os resultados encontrados para o arquivo atual
    if [ ${#FOUND_LOCATIONS[@]} -gt 0 ]; then
        # Deduplica as ocorrências (por exemplo, quando '.' e '/workspace' se sobrepõem)
        UNIQUE_LOCATIONS=($(echo "${FOUND_LOCATIONS[@]}" | tr ' ' '\n' | sort -u))
        
        for loc in "${UNIQUE_LOCATIONS[@]}"; do
            echo -e "  ${GREEN}[✓ ACHADO]${NC} $loc"
            ((FOUND_COUNT++))
        done
    else
        echo -e "  ${RED}[✗ NÃO ENCONTRADO]${NC} Nenhum arquivo correspondente nos diretórios pesquisados."
    fi
    echo ""
done

echo -e "${CYAN}=======================================================================${NC}"
echo -e "${GREEN}Varredura concluída! Total de registros encontrados: ${YELLOW}$FOUND_COUNT${NC}"
echo -e "${CYAN}=======================================================================${NC}"
