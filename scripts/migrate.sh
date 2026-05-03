#!/bin/bash
# Aplica todas as migrations em ordem no banco evolution
# Uso: ./scripts/migrate.sh
# Requer: container postgres rodando via docker-compose

set -e

DB_USER="${POSTGRES_USER:-root}"
DB_NAME="${POSTGRES_DB:-evolution}"

run_sql() {
    local file="$1"
    echo "▶ Aplicando: $file"
    docker exec -i postgres psql -U "$DB_USER" -d "$DB_NAME" < "$file"
    echo "✓ OK"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

run_sql "$SCRIPT_DIR/init-eklesia-db.sql"
run_sql "$SCRIPT_DIR/criar-tabela-bot-estados.sql"

# Migrations incrementais (pular se a coluna já for do tipo correto)
run_sql "$SCRIPT_DIR/003_migrate_hora_tipo.sql" 2>/dev/null || echo "  (já aplicado)"
run_sql "$SCRIPT_DIR/004_add_fk_escala.sql"     2>/dev/null || echo "  (já aplicado)"

echo ""
echo "Todas as migrations aplicadas com sucesso."