#!/bin/bash
# validate-migration.sh - Validação de Integridade Pós-Migração
# Disciplina: Implementação de Sistemas - UniFAAT

DB_ID="unifaat-db-6324558"
DB_USER="postgres"
DB_NAME="northwind"

echo "----------------------------------------------------------"
echo "Buscando endpoint para VALIDAÇÃO: $DB_ID..."
echo "----------------------------------------------------------"

# Busca o endpoint dinamicamente via AWS CLI
ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_ID \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text 2>/dev/null)

if [ "$ENDPOINT" == "None" ] || [ -z "$ENDPOINT" ]; then
    echo "ERRO: Instância não encontrada para validação."
    exit 1
fi

echo "Conectado em: $ENDPOINT"
export PGPASSWORD='unifaat123'

echo -e "\n1. LISTAGEM DE TABELAS MIGRADAS:"
echo "----------------------------------------------------------"
psql -h $ENDPOINT -U $DB_USER -d $DB_NAME -c "\dt"

echo -e "\n2. CONTAGEM DE REGISTROS (Tabela: orders):"
echo "----------------------------------------------------------"
psql -h $ENDPOINT -U $DB_USER -d $DB_NAME -c "SELECT count(*) AS total_pedidos FROM orders;"

echo -e "\n3. CONTAGEM DE REGISTROS (Tabela: products):"
echo "----------------------------------------------------------"
psql -h $ENDPOINT -U $DB_USER -d $DB_NAME -c "SELECT count(*) AS total_produtos FROM products;"

echo -e "\n----------------------------------------------------------"
echo "Validação concluída com sucesso!"
echo "----------------------------------------------------------"