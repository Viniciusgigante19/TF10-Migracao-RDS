#!/bin/bash
# migrate-data.sh - Automação de Migração de Dados
# Disciplina: Implementação de Sistemas - UniFAAT

# Carrega variáveis do arquivo .env localizado na raiz do RA
source "$(dirname "$0")/../.env"

DB_USER="postgres"

# Caminho dinâmico para o arquivo SQL
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$DIR/northwind_backup.sql"

echo "----------------------------------------------------------"
echo "Buscando endpoint para a instância: $DB_ID..."
echo "----------------------------------------------------------"

# Busca o endpoint dinamicamente via AWS CLI
ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text 2>/dev/null)

# Valida se o endpoint foi encontrado
if [ "$ENDPOINT" == "None" ] || [ -z "$ENDPOINT" ]; then
    echo "ERRO: Instância '$DB_ID' não encontrada ou ainda não está disponível."
    echo "Verifique no Console AWS se o status está 'Available'."
    exit 1
fi

# Verifica se o arquivo SQL existe
if [ ! -f "$SQL_FILE" ]; then
    echo "ERRO: Arquivo de backup não encontrado:"
    echo "$SQL_FILE"
    exit 1
fi

echo "Endpoint localizado: $ENDPOINT"
echo "Iniciando a restauração dos dados no banco '$DB_NAME'..."

# Exporta a senha para o psql não solicitar interação manual
export PGPASSWORD="$DB_PASSWORD"

# Executa a migração
psql -h "$ENDPOINT" -U "$DB_USER" -d "$DB_NAME" < "$SQL_FILE"

# Verifica se o comando anterior teve sucesso
if [ $? -eq 0 ]; then
    echo "----------------------------------------------------------"
    echo "SUCESSO: Migração concluída com êxito!"
    echo "----------------------------------------------------------"
else
    echo "----------------------------------------------------------"
    echo "ERRO: Falha na conexão ou na migração."
    echo "DICA: Verifique se o seu IP está liberado no Security Group (Porta 5432)."
    echo "----------------------------------------------------------"
    exit 1
fi