#!/usr/bin/env bash
# ==============================================================================
# 🚀 VOSTOK OS — WORKERS REPATCHER (SRE Tools v1.0)
# ==============================================================================
# Script de automação cirúrgica para migrar os workers locais concorrentes
# para o barramento assíncrono em lote (vostok-db-v7.go).
# ==============================================================================

set -euo pipefail

TARGET_ROOT="${1:-/home/jose/Vostok}"
WORKERS_FILE="${TARGET_ROOT}/pkg/db/workers.go"

# Cores para o terminal
CLR_RESET="\033[0m"
CLR_INFO="\033[0;34m"
CLR_SUCCESS="\033[0;32m"
CLR_WARN="\033[0;33m"
CLR_ERROR="\033[0;31m"

log_info() { echo -e "${CLR_INFO}[INFO] $(date '+%H:%M:%S') - $1${CLR_RESET}"; }
log_success() { echo -e "${CLR_SUCCESS}[SUCCESS] $(date '+%H:%M:%S') - $1${CLR_RESET}"; }
log_warn() { echo -e "${CLR_WARN}[WARN] $(date '+%H:%M:%S') - $1${CLR_RESET}"; }
log_error() { echo -e "${CLR_ERROR}[ERROR] $(date '+%H:%M:%S') - $1${CLR_RESET}"; }

echo -e "\033[1;36m🛰️  VOSTOK OS — WORKERS HIGH-THROUGHPUT MIGRATION\033[0m"
echo -e "\033[0;34m══════════════════════════════════════════════════════════════════════\033[0m"

# 1. Validação de segurança
if [ ! -f "$WORKERS_FILE" ]; then
    log_error "Arquivo não encontrado: ${WORKERS_FILE}"
    log_warn "Por favor, execute este script dentro da pasta raiz /home/jose/Vostok ou especifique o caminho."
    exit 1
fi

# 2. Criar backup protetor de SRE
log_info "Criando backup cirúrgico em: ${WORKERS_FILE}.bak"
cp "$WORKERS_FILE" "${WORKERS_FILE}.bak"

# 3. Aplicar patches com Python local
log_info "Injetando persistência assíncrona do vostok-db-v7.go..."

python3 -c "
import sys

filepath = '$WORKERS_FILE'
with open(filepath, 'r', encoding='utf-8') as f:
    code = f.read()

# Bloco 1: Substituição do InsertObservation por QueueObservation nos Workers
target_block = '''\t\t\terr = wp.manager.InsertObservation(obs)
\t\t\tif err != nil {
\t\t\t\tlog.Printf(\"\\\\033[0;31m❌ [WORKER-%d] Erro ao salvar observação %s no banco: %v\\\\033[0m\", id, obs.ID, err)
\t\t\t} else {
\t\t\t\tlog.Printf(\"\\\\033[0;32m✅ [WORKER-%d] Sucesso! Registro imutável de 9 colunas gravado: %s\\\\033[0m\", id, obs.ID)
\t\t\t\t// Realimenta a fila de forma autônoma (Mitose Atômica!)
\t\t\t\tif obs.Status == \"DONE\" {
\t\t\t\t\twp.enqueueDiscoveredURLs(obs.Payload)
\t\t\t\t}
\t\t\t}'''

replacement_block = '''\t\t\twp.manager.QueueObservation(obs)
\t\t\tlog.Printf(\"\\\\033[0;34m📥 [WORKER-%d] Registro %s enviado ao barramento de alta vazão\\\\033[0m\", id, obs.ID)
\t\t\tif obs.Status == \"DONE\" {
\t\t\t\twp.enqueueDiscoveredURLs(obs.Payload)
\t\t\t}'''

# Bloco 2: Substituição na falha (registerFailure)
target_fail = '_ = wp.manager.InsertObservation(obs)'
replacement_fail = 'wp.manager.QueueObservation(obs)'

patched = False

if target_block in code:
    code = code.replace(target_block, replacement_block)
    patched = True

if target_fail in code:
    code = code.replace(target_fail, replacement_fail)
    patched = True

if patched:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(code)
    print('SUCCESS')
else:
    print('FAILED')
" > /tmp/vostok_patch_status.txt

PATCH_STATUS=$(cat /tmp/vostok_patch_status.txt)

if [ "$PATCH_STATUS" = "SUCCESS" ]; then
    log_success "Workers migrados com sucesso para o barramento assíncrono!"
    echo -e "\033[0;34m══════════════════════════════════════════════════════════════════════\033[0m"
    log_success "PRONTO PARA COLETAR EM MASSA!"
    echo -e "Você pode decolar o sistema novamente rodando:"
    echo -e "  \033[1;32mgo run cmd/vostok/main.go\033[0m"
else
    log_error "Não foi possível aplicar o patch nos workers. O código pode já estar modificado ou as assinaturas diferem."
    log_warn "Restaurando backup de segurança..."
    mv "${WORKERS_FILE}.bak" "$WORKERS_FILE"
    exit 1
fi
echo -e "\033[0;34m══════════════════════════════════════════════════════════════════════\033[0m"
