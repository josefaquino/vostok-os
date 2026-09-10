#!/usr/bin/env bash
# ==============================================================================
# 🛰️  VOSTOK OS — GITHUB SEED ENGINE v1.0
# ==============================================================================
# Descrição: Alimenta a base de dados central com 50 repositórios de referência
#            do ecossistema open-source mundial (Biome: github_repository).
#            Gera assinaturas de metadados e scores reais baseados na RFC-0030
#            para visualização imediata no painel web (Observable Plot / D3).
# Uso: bash vostok-github-seeds.sh [caminho_do_banco]
# ==============================================================================

CLR_RESET="\033[0m"
CLR_INFO="\033[0;34m"
CLR_SUCCESS="\033[0;32m"
CLR_WARN="\033[0;33m"
CLR_ERROR="\033[0;31m"

log_info() { echo -e "${CLR_INFO}[INFO] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }
log_success() { echo -e "${CLR_SUCCESS}[SUCCESS] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }
log_warn() { echo -e "${CLR_WARN}[WARN] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }
log_error() { echo -e "${CLR_ERROR}[ERROR] $(date '+%Y-%m-%dT%H:%M:%SZ') - $1${CLR_RESET}" >&2; }

# 1. Definição do banco de dados alvo (SRE Local do Asus)
DB_PATH="$1"
if [ -z "$DB_PATH" ]; then
    # Procura nos locais previsíveis da colônia
    if [ -d "/home/jose/Vostok/data" ]; then
        DB_PATH="/home/jose/Vostok/data/frontier.db"
    elif [ -d "./Vostok/data" ]; then
        DB_PATH="./Vostok/data/frontier.db"
    elif [ -d "./data" ]; then
        DB_PATH="./data/frontier.db"
    else
        DB_PATH="./frontier.db"
    fi
fi

log_info "Iniciando alimentação de sementes para o biome GitHub..."
log_info "Banco de dados selecionado: $DB_PATH"

# 2. Definição da lista estática dos 50 repositórios de referência do ecossistema global
# Estrutura do array: "PROPRIETARIO/REPOSITORIO|CATEGORIA|STARS|ISSUES|DENSIDADE_DE_MANUTENCAO"
REPOS=(
    "golang/go|linguagem|125000|4500|94.5"
    "nodejs/node|backend|105000|3200|88.2"
    "python/cpython|linguagem|61000|1800|96.1"
    "django/django|backend|78000|1200|92.4"
    "rails/rails|backend|55000|980|89.3"
    "laravel/laravel|backend|76000|850|91.2"
    "gin-gonic/gin|backend|74000|320|95.0"
    "expressjs/express|backend|64000|430|75.4"
    "rust-lang/rust|linguagem|98000|8400|97.2"
    "denoland/deno|backend|49000|650|87.0"
    "sqlite/sqlite|banco|4100|150|99.5"
    "duckdb/duckdb|banco|21000|450|96.4"
    "pola-rs/polars|banco|28000|380|94.8"
    "pandas-dev/pandas|banco|43000|2900|90.1"
    "apache/spark|banco|38000|1800|86.3"
    "postgres/postgres|banco|13000|220|98.7"
    "redis/redis|banco|64000|890|94.1"
    "mongodb/mongo|banco|25000|1100|88.9"
    "clickhouse/clickhouse|banco|35000|1400|93.2"
    "scikit-learn/scikit-learn|ia|59000|2400|91.5"
    "pytorch/pytorch|ia|81000|5400|95.8"
    "tensorflow/tensorflow|ia|182000|6800|84.2"
    "huggingface/transformers|ia|128000|3100|97.4"
    "keras-team/keras|ia|60000|1200|89.5"
    "scipy/scipy|ia|12000|620|92.1"
    "numpy/numpy|ia|27000|1100|95.3"
    "milvus-io/milvus|ia|29000|410|91.0"
    "langchain-ai/langchain|ia|88000|2800|82.4"
    "ollama/ollama|ia|75000|520|96.8"
    "vllm-project/vllm|ia|28000|390|95.5"
    "kubernetes/kubernetes|devops|108000|3500|94.2"
    "docker/cli|devops|24000|450|89.1"
    "hashicorp/terraform|devops|42000|1600|88.4"
    "ansible/ansible|devops|61000|2100|85.9"
    "helm/helm|devops|26000|580|91.3"
    "prometheus/prometheus|devops|54000|940|92.7"
    "grafana/grafana|devops|62000|1800|93.0"
    "curl/curl|devops|32000|110|98.9"
    "git/git|devops|8900|120|99.1"
    "torvalds/linux|devops|178000|120|99.8"
    "facebook/react|frontend|224000|1200|93.4"
    "vuejs/core|frontend|46000|380|95.1"
    "angular/angular|frontend|95000|1600|87.6"
    "sveltejs/svelte|frontend|77000|620|92.0"
    "tailwindlabs/tailwindcss|frontend|82000|280|96.5"
    "webpack/webpack|frontend|64000|1100|78.3"
    "vitejs/vite|frontend|67000|490|97.1"
    "vercel/next.js|frontend|124000|2400|94.0"
    "gatsbyjs/gatsby|frontend|55000|1200|62.4"
    "jquery/jquery|frontend|59000|280|71.2"
)

# 3. Função para gerar inserts SQL ou emitir TSV
generate_sql_statements() {
    local count=1
    for item in "${REPOS[@]}"; do
        # Parsing das informações
        IFS='|' read -r repo cat stars issues health <<< "$item"
        
        local id="vst-git-$(printf "%03d" $count)"
        local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
        local biome="github_repository"
        local url="https://github.com/${repo}"
        local title="${repo}: ${cat} open-source module"
        local status="DONE"
        
        # Gera hash simples para simular o content_hash
        local hash=$(echo -n "$repo" | shasum -a 256 | cut -d' ' -f1 | head -c 32)
        local version="vostok-github-driver:v3.0"
        
        # Calcula scores derivados baseado na RFC-0030 para visualização fluida
        local activity_score=$(awk -v s="$stars" -v i="$issues" 'BEGIN { score = 100 - (i*100/s); if (score < 50) score=50; printf "%.2f", score }')
        local dep_health=$(awk -v h="$health" 'BEGIN { printf "%.2f", h * 0.98 }')
        local gov_score=$(awk -v s="$stars" 'BEGIN { g = s > 50000 ? 95.0 : 85.0; printf "%.2f", g }')
        
        # O Health Score consolidado (fórmula RFC-0030 equilibrada)
        local health_score=$(awk -v a="$activity_score" -v d="$dep_health" -v g="$gov_score" 'BEGIN { printf "%.2f", (a*0.3 + d*0.4 + g*0.3) }')
        
        # Determina o status de risco para representação visual
        local risk_label="HEALTHY"
        if (( $(echo "$health_score < 75.0" | bc -l) )); then
            risk_label="AT_RISK"
        elif (( $(echo "$health_score < 85.0" | bc -l) )); then
            risk_label="STABLE"
        fi

        # Monta payload JSON estruturado sob a Rota B
        local payload="{\"stars\":$stars,\"open_issues\":$issues,\"activity_score\":$activity_score,\"dependency_health\":$dep_health,\"governance_score\":$gov_score,\"maintenance_score\":$health,\"health_score\":$health_score,\"risk_label\":\"$risk_label\",\"category\":\"$cat\"}"
        
        # Escapa aspas para SQL
        local escaped_payload=$(echo "$payload" | sed "s/'/''/g")
        local escaped_title=$(echo "$title" | sed "s/'/''/g")

        echo "INSERT OR REPLACE INTO observations (id, timestamp, biome, source_url, title, status, content_hash, driver_version, payload) VALUES ('$id', '$timestamp', '$biome', '$url', '$escaped_title', '$status', '$hash', '$version', '$escaped_payload');"
        
        ((count++))
    done
}

# 4. Execução da persistência ou amostragem
if [ ! -f "$DB_PATH" ]; then
    log_warn "O arquivo de banco de dados não foi localizado em: $DB_PATH"
    log_warn "Certifique-se de executar o vostok-bootstrap.sh primeiro para criar o banco de dados."
    log_warn "Cuspindo as queries SQL no stdout para importação futura..."
    echo "----------------------------------------------------------------"
    generate_sql_statements
    echo "----------------------------------------------------------------"
    exit 0
fi

# Se o banco existe, vamos verificar se o comando 'sqlite3' está disponível
if ! command -v sqlite3 &> /dev/null; then
    log_warn "Comando 'sqlite3' não encontrado no barramento local!"
    log_warn "Cuspindo as queries SQL no stdout..."
    generate_sql_statements
    exit 0
fi

# Executa as inserções de forma atômica no banco SQLite WAL
log_info "Populando as 50 sementes de biomes do GitHub no banco SQLite WAL..."

# Prepara arquivo temporário de comandos SQL
SQL_TEMP="/tmp/vostok_seeds.sql"
echo "BEGIN TRANSACTION;" > "$SQL_TEMP"
generate_sql_statements >> "$SQL_TEMP"
echo "COMMIT;" >> "$SQL_TEMP"

# Roda a transação no SQLite
sqlite3 "$DB_PATH" < "$SQL_TEMP"
rm -f "$SQL_TEMP"

log_success "Sucesso! 50 organismos do biome GitHub injetados e catalogados com sucesso!"
log_info "Você já pode rodar 'go run cmd/vostok/main.go' e abrir http://localhost:8080 para explorar o cockpit!"
