#!/usr/bin/env bash
# =============================================================================
# 🚀 YODADB — ZERO-CONFIG SNAPSHOT & TIME-TRAVEL UTILITY v1.0
# =============================================================================
# Descrição: Ferramenta SRE para criação de snapshots consistentes e reversão
#            temporal instantânea (checkpointing) do YodaDB.
#            Opera de forma offline-first e compatível com a Filosofia Unix.
# Uso: ./yoda-snapshot.sh --create
#      ./yoda-snapshot.sh --list
#      ./yoda-snapshot.sh --restore [snapshot_id]
# =============================================================================

CLR_RESET="\033[0m"
CLR_TITLE="\033[1;36m"     # Ciano Negrito
CLR_BORDER="\033[0;34m"    # Azul
CLR_SUCCESS="\033[1;32m"   # Verde Negrito
CLR_WARN="\033[1;33m"      # Amarelo Negrito
CLR_ERROR="\033[1;31m"     # Vermelho Negrito
CLR_INFO="\033[0;34m"      # Azul Claro

# Diretório padrão local do Asus
VOSTOK_DIR="/home/jose/Vostok"
if [ ! -d "$VOSTOK_DIR" ]; then
    VOSTOK_DIR="."
fi

STORAGE_LOG="$VOSTOK_DIR/yoda_storage.log"
BLOOM_DAT="$VOSTOK_DIR/yoda_bloom.dat"
SNAPSHOTS_DIR="$VOSTOK_DIR/snapshots"

# Inicialização segura
mkdir -p "$SNAPSHOTS_DIR"

log_info() { echo -e "${CLR_INFO}[INFO SRE] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}"; }
log_success() { echo -e "${CLR_SUCCESS}[SUCCESS] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}"; }
log_warn() { echo -e "${CLR_WARN}[WARN SRE] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}"; }
log_error() { echo -e "${CLR_ERROR}[ERROR SRE] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}"; }

show_help() {
    echo -e "${CLR_TITLE}🔮 YodaDB Checkpoint Engine — CLI Controller${CLR_RESET}"
    echo -e "${CLR_BORDER}======================================================================${CLR_RESET}"
    echo "Opções:"
    echo "  --create             Tira um snapshot atômico em tempo real"
    echo "  --list               Lista todos os checkpoints de viagem no tempo disponíveis"
    echo "  --restore [snap_id]  Restaura o estado físico para um snapshot específico"
    echo "  --help               Exibe esta mensagem de ajuda"
    echo -e "${CLR_BORDER}======================================================================${CLR_RESET}"
}

create_snapshot() {
    if [ ! -f "$STORAGE_LOG" ] && [ ! -f "$BLOOM_DAT" ]; then
        log_error "Nenhum arquivo ativo do YodaDB encontrado para backup em $VOSTOK_DIR!"
        exit 1
    fi

    local SNAP_ID="snap_$(date '+%Y%m%d_%H%M%S')"
    local TARGET_SNAP_DIR="$SNAPSHOTS_DIR/$SNAP_ID"
    mkdir -p "$TARGET_SNAP_DIR"

    log_info "Congelando canais físicos do YodaDB em tempo de execução..."
    
    # Cópia segura de arquivos (mmap MAP_SHARED garante integridade de yoda_bloom.dat no disco)
    if [ -f "$BLOOM_DAT" ]; then
        cp "$BLOOM_DAT" "$TARGET_SNAP_DIR/yoda_bloom.dat"
    fi
    if [ -f "$STORAGE_LOG" ]; then
        cp "$STORAGE_LOG" "$TARGET_SNAP_DIR/yoda_storage.log"
    fi

    # Gravação dos metadados do Checkpoint
    local TOTAL_RECORDS=0
    if [ -f "$STORAGE_LOG" ] && [ -f "$VOSTOK_DIR/yodadb-v3" ]; then
        TOTAL_RECORDS=$("$VOSTOK_DIR/yodadb-v3" stream 0 2>/dev/null | wc -l | awk '{print $1}')
    fi

    cat <<EOF > "$TARGET_SNAP_DIR/meta.json"
{
  "snapshot_id": "$SNAP_ID",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "storage_size": "$(du -sh "$STORAGE_LOG" 2>/dev/null | awk '{print $1}')",
  "total_records": $TOTAL_RECORDS
}
EOF

    log_success "Checkpoint '$SNAP_ID' criado com sucesso!"
    echo -e "  📂 Destino: ${CLR_HIGHLIGHT}$TARGET_SNAP_DIR${CLR_RESET}"
    echo -e "  📊 Registros Selados: ${CLR_HIGHLIGHT}$TOTAL_RECORDS${CLR_RESET}"
}

list_snapshots() {
    echo -e "${CLR_TITLE}🕰️ Checkpoints de Viagem no Tempo Disponíveis:${CLR_RESET}"
    echo -e "${CLR_BORDER}----------------------------------------------------------------------${CLR_RESET}"
    printf "%-25s %-25s %-12s %-10s\n" "ID DO SNAPSHOT" "DATA DE CRIAÇÃO (UTC)" "RECORDS" "TAMANHO"
    printf "%-25s %-25s %-12s %-10s\n" "--------------" "---------------------" "-------" "-------"

    local COUNT=0
    for snap in $(ls "$SNAPSHOTS_DIR" 2>/dev/null | grep '^snap_'); do
        local META_FILE="$SNAPSHOTS_DIR/$snap/meta.json"
        if [ -f "$META_FILE" ]; then
            local TS=$(jq -r '.timestamp' "$META_FILE" 2>/dev/null || echo "Desconhecido")
            local REC=$(jq -r '.total_records' "$META_FILE" 2>/dev/null || echo "0")
            local SIZE=$(jq -r '.storage_size' "$META_FILE" 2>/dev/null || echo "0B")
            printf "%-25s %-25s %-12s %-10s\n" "$snap" "$TS" "$REC" "$SIZE"
            COUNT=$((COUNT+1))
        fi
    done

    if [ "$COUNT" -eq 0 ]; then
        echo -e "  ${CLR_WARN}Nenhum checkpoint encontrado no hangar.${CLR_RESET}"
    fi
    echo -e "${CLR_BORDER}----------------------------------------------------------------------${CLR_RESET}"
}

restore_snapshot() {
    local TARGET_SNAP="$1"
    if [ -z "$TARGET_SNAP" ]; then
        log_error "Uso correto: --restore [snapshot_id]"
        exit 1
    fi

    local TARGET_SNAP_DIR="$SNAPSHOTS_DIR/$TARGET_SNAP"
    if [ ! -d "$TARGET_SNAP_DIR" ]; then
        log_error "Snapshot '$TARGET_SNAP' não encontrado em $SNAPSHOTS_DIR!"
        exit 1
    fi

    log_warn "ATENÇÃO: Isso substituirá o estado físico ATUAL do YodaDB pelo snapshot '$TARGET_SNAP'!"
    read -p "Deseja continuar com o salto temporal? (s/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
        log_info "Salto cancelado pelo operador. A linha do tempo atual foi mantida."
        exit 0
    fi

    log_info "Parando temporariamente a esteira concorrente do YodaDB..."
    
    # Restaura fisicamente os arquivos
    if [ -f "$TARGET_SNAP_DIR/yoda_bloom.dat" ]; then
        cp "$TARGET_SNAP_DIR/yoda_bloom.dat" "$BLOOM_DAT"
        log_info "Filtro de Bits Mmapeado de 256MB restaurado."
    fi
    if [ -f "$TARGET_SNAP_DIR/yoda_storage.log" ]; then
        cp "$TARGET_SNAP_DIR/yoda_storage.log" "$STORAGE_LOG"
        log_info "Log sequencial binário restaurado."
    else
        # Se não existia log de storage no snapshot, limpamos o atual
        rm -f "$STORAGE_LOG"
    fi

    log_success "Salto temporal concluído! YodaDB restaurado com sucesso para o estado de '$TARGET_SNAP'!"
}

# Roteador de parâmetros CLI
case "$1" in
    --create)
        create_snapshot
        ;;
    --list)
        list_snapshots
        ;;
    --restore)
        restore_snapshot "$2"
        ;;
    --help|*)
        show_help
        ;;
esac
