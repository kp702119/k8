#!/bin/bash

# Script to store Product Service staging secrets in Vault
# Requires VAULT_TOKEN with write permissions

set -e

VAULT_ADDR="http://10.10.80.77:30820"

if [ -z "$VAULT_TOKEN" ]; then
  echo "❌ Error: VAULT_TOKEN environment variable is not set"
  echo "Please set it with: export VAULT_TOKEN=your-write-token"
  exit 1
fi

echo "🔐 Storing Product Service Staging Secrets in Vault"
echo "===================================================="

# Product Service Database
echo "📦 Storing Product Service Database Secret..."
curl -s -X POST ${VAULT_ADDR}/v1/secret/data/wingyip-srs/staging/product/database \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "connectionstring": "Data Source=tcp:10.10.80.81,1433;Initial Catalog=WingYip_SRS_Product_Database;User Id=sa;Password=1n9pp2.0@123;TrustServerCertificate=True;Encrypt=False"
    }
  }' | jq -r '.errors // "✅ Success"'

# Product Service URLs
echo "📦 Storing Product Service URLs..."
curl -s -X POST ${VAULT_ADDR}/v1/secret/data/wingyip-srs/staging/product/services \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "administrationservice": "http://10.10.80.77:32333/",
      "productservice": "http://10.10.80.77:31085/",
      "spacemanservice": "http://10.10.80.77:30800/",
      "stockservice": "http://10.10.80.77:30385/",
      "orderservice": "http://10.10.80.77:32500/",
      "auditservice": "http://10.10.80.77:31111/",
      "notificationservice": "http://10.10.80.77:32600/"
    }
  }' | jq -r '.errors // "✅ Success"'

# ElasticSearch Configuration
echo "📦 Storing ElasticSearch Configuration..."
curl -s -X POST ${VAULT_ADDR}/v1/secret/data/wingyip-srs/staging/product/elasticsearch \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "url": "http://10.10.80.77:32000/",
      "numberoreshards": "1",
      "numberofreplicas": "0"
    }
  }' | jq -r '.errors // "✅ Success"'

# RabbitMQ (Shared)
echo "🐰 Storing RabbitMQ Secrets..."
curl -s -X POST ${VAULT_ADDR}/v1/secret/data/wingyip-srs/staging/shared/rabbitmq \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "hostname": "10.10.80.77",
      "port": "32210",
      "username": "admin",
      "password": "RabbitMQ@2025"
    }
  }' | jq -r '.errors // "✅ Success"'

echo ""
echo "✅ All Product Service staging secrets stored in Vault!"
echo ""
echo "📋 Verify with:"
echo "  curl -s -X GET ${VAULT_ADDR}/v1/secret/data/wingyip-srs/staging/product/database -H \"X-Vault-Token: \${VAULT_TOKEN}\" | jq"
