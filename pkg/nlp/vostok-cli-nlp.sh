#!/usr/bin/env bash
# ==============================================================================
# 🛰️  VOSTOK OS — CLI-NLP PROCESSOR v3.0 (Clean Slate)
# ==============================================================================
# Descrição: Processador de Linguagem Natural purista via linha de comando (CLI-NLP).
#            Migrado e adaptado sob o Manifesto da Nova Gênese do Vostok OS.
#            Analisa relatórios da SEC/CVM buscando assinaturas de risco climático
#            e resiliência corporativa de forma offline-first e eficiente.
# Contratos: Saída estruturada de dados estritamente em stdout (9 colunas - TSV).
#            Format: [id, timestamp, bioma, source_url, title, status, content_hash, driver_version, payload]
#            Logs de auditoria e métricas de SRE estritamente em stderr.
# ==============================================================================

# Cores ANSI para logs em stderr
CLR_RESET="\033[0m"
CLR_INFO="\033[0;34m"
CLR_SUCCESS="\033[0;32m"
CLR_WARN="\033[0;33m"
CLR_ERROR="\033[0;31m"

# Função para logar no canal stderr (Isolamento de SRE)
log_info() { echo -e "${CLR_INFO}[INFO] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }
log_success() { echo -e "${CLR_SUCCESS}[SUCCESS] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }
log_warn() { echo -e "${CLR_WARN}[WARN] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }
log_error() { echo -e "${CLR_ERROR}[ERROR] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }

# 1. Preparação do ambiente temporário no sandbox (Scratch)
SCRATCH_DIR="/workspace/scratch/vostok-nlp-sandbox"
mkdir -p "$SCRATCH_DIR"

# 2. Entrada de dados
# Se um arquivo for passado como argumento, usamos ele. Caso contrário, criamos uma simulação.
INPUT_FILE="$1"
if [ -z "$INPUT_FILE" ]; then
    INPUT_FILE="$SCRATCH_DIR/risk_factors.txt"
    log_warn "Nenhum arquivo de entrada fornecido. Gerando amostra de teste (DFP/CVM)..."
    cat << 'EOF' > "$INPUT_FILE"
Item 1A. Fatores de Risco - Relatório Anual (DFP - CVM)
Nossas operações industriais estão expostas a riscos ambientais severos decorrentes de mudanças climáticas globais.
O aumento na frequência de eventos climáticos extremos na região costeira brasileira, tais como tempestades,
inundações florestais e secas prolongadas, pode causar danos físicos graves às nossas plantas industriais.
Adicionalmente, a transição para uma economia de baixo carbono impõe riscos regulatórios significativos.
A introdução de novos tributos sobre emissões de carbono e regras rígidas de conformidade ambiental aumentará
nossos custos operacionais. A incapacidade de cumprir com as expectativas de ESG de nossos investidores
pode reduzir drasticamente o valuation de mercado e a resiliência financeira corporativa de nossa companhia.
EOF
fi

# 3. Definição de Stopwords locais (Scrub)
STOPWORDS_FILE="$SCRATCH_DIR/stopwords.txt"
for word in de o a do da em para com por um uma os as nos nas se sob sobre como para; do
    echo "$word" >> "$STOPWORDS_FILE"
done

log_info "Iniciando processamento Vostok CLI-NLP do arquivo: $INPUT_FILE"

if [ ! -f "$INPUT_FILE" ]; then
    log_error "Erro físico: Arquivo de entrada não encontrado!"
    exit 1
fi

# 4. Tokenização e Limpeza (Scrub & Explore)
# Converte para minúsculas, remove pontuação, coloca uma palavra por linha
log_info "Tokenizando o corpus..."
TOKENS_RAW="$SCRATCH_DIR/tokens_raw.txt"
tr '[:upper:]' '[:lower:]' < "$INPUT_FILE" | tr -cs 'a-z' '\n' > "$TOKENS_RAW"

TOTAL_WORDS=$(wc -l < "$TOKENS_RAW")
log_info "Total de palavras cruas (tokens): $TOTAL_WORDS"

# Filtragem de Stopwords (Exclusão rápida via grep -Fv)
TOKENS_FILTERED="$SCRATCH_DIR/tokens_filtered.txt"
grep -Fv -f "$STOPWORDS_FILE" "$TOKENS_RAW" > "$TOKENS_FILTERED"

# Cálculo do hash do conteúdo puro (content_hash)
CONTENT_HASH=$(shasum -a 256 "$INPUT_FILE" | cut -d' ' -f1)

# 5. Dicionário de Risco Climático e Resiliência (Mapeamento Semântico)
CLIMATE_DICT="$SCRATCH_DIR/climate_keywords.txt"
cat << 'EOF' > "$CLIMATE_DICT"
clima
climaticas
tempestades
inundacoes
secas
carbono
emissoes
esg
ambiental
resiliencia
riscos
EOF

log_info "Buscando assinaturas de risco climático e resiliência..."
MATCHES_FILE="$SCRATCH_DIR/matches.txt"
grep -F -f "$CLIMATE_DICT" "$TOKENS_FILTERED" > "$MATCHES_FILE"

CLIMATE_COUNT=$(wc -l < "$MATCHES_FILE")
log_info "Ocorrências encontradas: $CLIMATE_COUNT"

# 6. Modelagem (Model) - Cálculo do Score via AWK local (O(1) Memory)
DENSITY_SCORE=$(awk -v count="$CLIMATE_COUNT" -v total="$TOTAL_WORDS" 'BEGIN { printf "%.4f", (count/total)*100 }')
log_success "Densidade semântica calculada: $DENSITY_SCORE%"

# 7. Normalização para o NOVO Contrato Vostok OS v3 (9 colunas - TSV)
# Colunas: id | timestamp | bioma | source_url | title | status | content_hash | driver_version | payload (JSON)
ID="vst-nlp-$(date +%s)"
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
BIOMA="cvm_companhia"
SOURCE_URL="https://dados.cvm.gov.br/dados/CIA_ABERTA/DOC/DFP/DADOS/dfp_cia_aberta_2026.zip"
TITLE="DFP PETROBRAS 2026 - ANÁLISE DE RISCO"
STATUS="DONE"
DRIVER_VERSION="vostok-cli-nlp:v3.0"

# Construção do Payload JSON compacto
PAYLOAD_JSON="{\"climate_risk_density\":$DENSITY_SCORE,\"total_words\":$TOTAL_WORDS,\"matches_found\":$CLIMATE_COUNT,\"engine\":\"vostok-nlp-core\"}"

# Impressão do cabeçalho estruturado no stdout
echo -e "id\ttimestamp\tbioma\tsource_url\ttitle\tstatus\tcontent_hash\tdriver_version\tpayload"

# Emissão da linha purificada no stdout
echo -e "${ID}\t${TIMESTAMP}\t${BIOMA}\t${SOURCE_URL}\t${TITLE}\t${STATUS}\t${CONTENT_HASH}\t${DRIVER_VERSION}\t${PAYLOAD_JSON}"

# Limpeza física do sandbox para manter o metal imaculado
rm -rf "$SCRATCH_DIR"
log_success "Migração concluída e sandbox de execução limpo."

