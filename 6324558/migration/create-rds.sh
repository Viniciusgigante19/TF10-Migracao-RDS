#!/bin/bash
# create-rds.sh - Criação com suporte a IPv4 e IPv6

source "$(dirname "$0")/../.env"

echo "1. Obtendo ID da VPC padrão..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)

echo "2. Criando Security Group para o RDS..."
SG_ID=$(aws ec2 create-security-group \
    --group-name "RDS-SG-TF10-$(date +%s)" \
    --description "Acesso Dual Stack para TF10" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)

echo "3. Capturando e autorizando IPs..."

# Captura IPv4
MY_IPV4=$(curl -s -4 https://checkip.amazonaws.com)
if [ ! -z "$MY_IPV4" ]; then
    echo "Liberando IPv4: $MY_IPV4"
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 5432 \
        --cidr "$MY_IPV4/32"
fi

# Captura IPv6
MY_IPV6=$(curl -s -6 ifconfig.me)
if [[ "$MY_IPV6" == *":"* ]]; then
    echo "Liberando IPv6: $MY_IPV6"
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 5432 \
        --ipv6-cidr "$MY_IPV6/128"
fi

echo "4. Criando instância RDS (Dual-Stack)..."
aws rds create-db-instance \
    --db-instance-identifier "$DB_ID" \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 20 \
    --master-username postgres \
    --master-user-password "$DB_PASSWORD" \
    --db-name "$DB_NAME" \
    --publicly-accessible \
    --vpc-security-group-ids "$SG_ID" \
    --storage-type gp3 \
    --network-type dual \
    --backup-retention-period 1 \
    --tags Key=Disciplina,Value=ImplementacaoSistemas Key=Aluno,Value=Vinicius \
    --region "$AWS_REGION" \
| tee create-rds-log.json

echo "---------------------------------------------------------------"
echo "Infraestrutura enviada. IPs autorizados: $MY_IPV4 e $MY_IPV6"
echo "---------------------------------------------------------------"