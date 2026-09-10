#!/bin/bash
# explore_berkeley_db.sh
# Script interativo para explorar o código-fonte do Berkeley DB (versão 5.3.28)

set -euo pipefail

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Caminho do código-fonte
BASE_DIR="${HOME}/Vostok/db-5.3.28"
BTREE_DIR="${BASE_DIR}/src/btree"

# Verificar se o diretório existe
if [ ! -d "$BTREE_DIR" ]; then
    echo -e "${RED}❌ Diretório do Berkeley DB não encontrado em ${BTREE_DIR}${NC}"
    echo "Certifique-se de que o código foi baixado e extraído."
    exit 1
fi

# Função: Listar os arquivos principais da B-tree
list_btree_files() {
    echo -e "${CYAN}📂 Arquivos fonte da B-tree:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    ls -lh "$BTREE_DIR"/*.c "$BTREE_DIR"/*.h 2>/dev/null | awk '{print $9, "(" $5 ")"}'
    echo ""
    echo "Arquivos principais:"
    echo "  btree.c          - Implementação geral da B-tree"
    echo "  bt_put.c         - Inserção de chave/valor"
    echo "  bt_get.c         - Busca por chave"
    echo "  bt_cursor.c      - Cursor para iteração"
    echo "  bt_rec.c         - Recuperação (WAL/recovery)"
    echo "  bt_split.c       - Split de páginas"
    echo "  bt_delete.c      - Remoção de chave"
}

# Função: Mostrar a estrutura da página B-tree
show_btree_struct() {
    echo -e "${CYAN}📐 Estruturas de dados principais:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    echo -e "${YELLOW}B-tree page structure (from bt_page.h):${NC}"
    grep -A 20 "typedef struct __bt_page" "$BTREE_DIR/../dbinc/btree.h" 2>/dev/null || \
    grep -A 20 "struct __bt_page" "$BTREE_DIR"/*.h 2>/dev/null | head -30
    echo ""
    echo -e "${YELLOW}B-tree cursor structure:${NC}"
    grep -A 15 "typedef struct __bt_cursor" "$BTREE_DIR"/*.h 2>/dev/null | head -20
}

# Função: Buscar por uma função específica
search_function() {
    read -p "Digite o nome da função (ex: btree_open, bt_put, bt_get): " func
    if [ -z "$func" ]; then
        echo "Nome da função não pode ser vazio."
        return
    fi
    echo -e "${CYAN}🔍 Buscando por '${func}' em todos os arquivos .c e .h:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    grep -n --color=always "$func" "$BTREE_DIR"/*.c "$BTREE_DIR"/*.h 2>/dev/null | head -50
    if [ $? -ne 0 ]; then
        echo "Nenhuma ocorrência encontrada."
    fi
}

# Função: Listar todas as funções definidas no código
list_functions() {
    echo -e "${CYAN}📋 Funções definidas nos arquivos .c:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    grep -h "^[a-zA-Z_][a-zA-Z0-9_]*\s*(" "$BTREE_DIR"/*.c 2>/dev/null | \
        sed 's/(.*//' | sed 's/^[[:space:]]*//' | sort -u | head -50
    echo "... (mostrando apenas as 50 primeiras)"
}

# Função: Mostrar comentários/documentação
show_documentation() {
    echo -e "${CYAN}📝 Documentação e comentários importantes:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    echo -e "${YELLOW}Comentários sobre a B-tree (topo dos arquivos):${NC}"
    for file in "$BTREE_DIR"/*.c; do
        echo -e "${BLUE}--- $(basename $file) ---${NC}"
        head -30 "$file" | grep -E '^/\*|^\*' | head -10
        echo ""
    done | head -50
}

# Função: Contar linhas de código por arquivo
count_lines() {
    echo -e "${CYAN}📊 Contagem de linhas por arquivo:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    (cd "$BTREE_DIR" && wc -l *.c *.h 2>/dev/null | sort -rn) | head -15
}

# Função: Buscar includes e dependências
show_includes() {
    echo -e "${CYAN}🔗 Includes e dependências:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    grep -h "^#include" "$BTREE_DIR"/*.c "$BTREE_DIR"/*.h 2>/dev/null | sort | uniq -c | sort -rn
}

# Função: Exibir um arquivo específico
view_file() {
    read -p "Digite o nome do arquivo (ex: btree.c): " filename
    if [ -f "$BTREE_DIR/$filename" ]; then
        less "$BTREE_DIR/$filename"
    else
        echo "Arquivo não encontrado. Tente: $(ls $BTREE_DIR/*.c | xargs -n1 basename | head -5)"
    fi
}

# Menu principal
while true; do
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}       🗡️  EXPLORADOR DO BERKELEY DB (B-TREE)                 ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}1.${NC} Listar arquivos da B-tree"
    echo -e "${GREEN}2.${NC} Mostrar estruturas de dados principais"
    echo -e "${GREEN}3.${NC} Buscar por uma função"
    echo -e "${GREEN}4.${NC} Listar funções definidas"
    echo -e "${GREEN}5.${NC} Mostrar documentação/comentários"
    echo -e "${GREEN}6.${NC} Contar linhas de código"
    echo -e "${GREEN}7.${NC} Mostrar includes e dependências"
    echo -e "${GREEN}8.${NC} Visualizar um arquivo (less)"
    echo -e "${GREEN}9.${NC} Sair"
    echo ""
    read -p "Escolha uma opção: " choice

    case $choice in
        1) list_btree_files ;;
        2) show_btree_struct ;;
        3) search_function ;;
        4) list_functions ;;
        5) show_documentation ;;
        6) count_lines ;;
        7) show_includes ;;
        8) view_file ;;
        9) echo "Saindo..."; break ;;
        *) echo -e "${RED}Opção inválida.${NC}" ;;
    esac
done
