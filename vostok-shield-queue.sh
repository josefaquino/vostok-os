#!/bin/bash
# ==============================================================================
# 🚀 VOSTOK OS — SHIELD & CLEAN QUEUE (SRE Security Patch)
# ==============================================================================
# Descrição: Script utilitário para expurgar redes sociais hostis da fila 
#            do banco de dados SQLite WAL e blindar o driver HTML contra 
#            futuras inserções dessas plataformas (captchas/rate-limits).
# Autor: R2-Kyber & Comandante Anakin
# ==============================================================================

# Cores ANSI para feedback limpo no console do Asus
CLR_RESET="\033[0m"
CLR_TITLE="\033[1;36m"     # Ciano Negrito
CLR_BORDER="\033[0;34m"    # Azul
CLR_HIGHLIGHT="\033[1;32m" # Verde Negrito
CLR_WARN="\033[1;33m"      # Amarelo Negrito

DB_PATH="data/frontier.db"
if [ ! -f "$DB_PATH" ] && [ -f "/home/jose/Vostok/data/frontier.db" ]; then
    DB_PATH="/home/jose/Vostok/data/frontier.db"
fi

echo -e "${CLR_TITLE}🛰️  VOSTOK OS — SHIELD & CLEAN QUEUE INITIATED${CLR_RESET}"
echo -e "${CLR_BORDER}══════════════════════════════════════════════════════════════════════${CLR_RESET}"

# 1. Limpeza Sanitária na Fila SQLite (Expulsa Redes Sociais com Status SKIPPED)
if [ -f "$DB_PATH" ]; then
    echo -e "${CLR_HIGHLIGHT}[PASSO 1/2] Higienizando Fila no SQLite WAL...${CLR_RESET}"
    
    # Executa a query de expurgo e conta as linhas afetadas
    SQL_CLEAN="
    UPDATE observations 
    SET status = 'SKIPPED' 
    WHERE status = 'QUEUED' 
      AND (source_url LIKE '%instagram.com%' 
        OR source_url LIKE '%linkedin.com%' 
        OR source_url LIKE '%x.com%' 
        OR source_url LIKE '%twitter.com%' 
        OR source_url LIKE '%tumblr.com%'
        OR source_url LIKE '%facebook.com%'
        OR source_url LIKE '%tiktok.com%');
    "
    sqlite3 "$DB_PATH" "$SQL_CLEAN"
    
    # Exibe volumetria pós-limpeza
    echo -e "✅ Fila sanitizada com sucesso!"
    echo -e "\n📊 Estado atualizado da Fila de Espera (Top 10 Domínios):"
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
else
    echo -e "${CLR_WARN}[AVISO SRE] Banco de dados '$DB_PATH' não encontrado para limpeza local.${CLR_RESET}"
fi

echo -e "${CLR_BORDER}──────────────────────────────────────────────────────────────────────${CLR_RESET}"

# 2. Blindagem de Código (Patch Python nos Drivers e Bootstrappers do Vostok)
echo -e "${CLR_HIGHLIGHT}[PASSO 2/2] Aplicando Escudo Taxonômico Preventivo nos Arquivos de Código...${CLR_RESET}"

python3 - <<'EOF'
import os
import re

files_to_patch = [
    "drivers/html-driver-v2.go",
    "vostok-html-driver-polished-v2.go",
    "vostok-bootstrap-v12.sh",
    "vostok-bootstrap-v11.sh",
    "vostok-bootstrap.sh"
]

blacklist_decl = """// RegExp para bloqueio de Redes Sociais e Domínios Hostis (Escudo Taxonômico)
var socialBlacklistRegex = regexp.MustCompile(`(?i)(instagram\\.com|linkedin\\.com|x\\.com|twitter\\.com|tumblr\\.com|facebook\\.com|tiktok\\.com)`)"""

patched_any = False

for filepath in files_to_patch:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if "socialBlacklistRegex" not in content:
            # 1. Inserir declaração da regex
            pattern_regex = r"(var staticAssetRegex = regexp\.MustCompile\(`[^`]+`\))"
            replacement_regex = r"\1\n\n" + blacklist_decl
            content = re.sub(pattern_regex, replacement_regex, content)
            
            # 2. Inserir validação lógica dentro de isValidTarget
            pattern_validation = r"(if staticAssetRegex\.MatchString\(urlStr\) {\s+return false\s+})"
            replacement_validation = r"\1\n\tif socialBlacklistRegex.MatchString(urlStr) {\n\t\treturn false\n\t}"
            content = re.sub(pattern_validation, replacement_validation, content)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  \033[1;32m✓\033[0m Patch aplicado com sucesso em: {filepath}")
            patched_any = True
        else:
            print(f"  \033[1;33m-\033[0m {filepath} já possui o Escudo contra Redes Sociais ativo.")
    else:
        # Silencioso se o arquivo não existe localmente na pasta atual
        pass

if patched_any:
    print("\n\033[1;32m[SUCESSO] Código blindado contra crawler-hostility!\033[0m")
else:
    print("\n\033[1;33m[INFO] Nenhuma modificação pendente nos arquivos de código locais.\033[0m")
EOF

echo -e "${CLR_BORDER}══════════════════════════════════════════════════════════════════════${CLR_RESET}"
echo -e "${CLR_HIGHLIGHT}🚀 PROTOCOLO DE BLINDAGEM CONCLUÍDO!${CLR_RESET}"
echo -e "Se você modificou os drivers Go, lembre-se de recompilar o sistema executando:"
echo -e "${CLR_WARN}  go run cmd/vostok/main.go${CLR_RESET}"
echo -e "${CLR_BORDER}══════════════════════════════════════════════════════════════════════${CLR_RESET}"
