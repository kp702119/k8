#!/bin/bash

# Script to store staging environment secrets in HashiCorp Vault
# Run this script to populate Vault with all staging secrets

set -e

VAULT_ADDR="http://10.10.80.77:30820"
VAULT_TOKEN="${VAULT_TOKEN:-your-vault-token-here}"

echo "🔐 Storing Staging Secrets in Vault"
echo "===================================="

# Database Connection Strings
echo "📦 Storing Database Secrets..."

vault kv put secret/wingyip-srs/staging/administration/database \
  connectionstring="Data Source=tcp:10.10.80.75,1433;Initial Catalog=WingYip_SRS_Administration_Database;User Id=sa;Password=1n9pp2.0@123;TrustServerCertificate=True;Encrypt=False"

vault kv put secret/wingyip-srs/staging/audit/database \
  connectionstring="Data Source=tcp:10.10.80.75,1433;Initial Catalog=WingYip_SRS_Audit_Database;User Id=sa;Password=1n9pp2.0@123;TrustServerCertificate=True;Encrypt=False"

vault kv put secret/wingyip-srs/staging/authentication/database \
  connectionstring="Data Source=tcp:10.10.80.75,1433;Initial Catalog=WingYip_SRS_Authentication_Database;User Id=sa;Password=1n9pp2.0@123;TrustServerCertificate=True;Encrypt=False"

vault kv put secret/wingyip-srs/staging/product/database \
  connectionstring="Data Source=tcp:10.10.80.81,1433;Initial Catalog=WingYip_SRS_Product_Database;User Id=sa;Password=1n9pp2.0@123;TrustServerCertificate=True;Encrypt=False"

vault kv put secret/wingyip-srs/staging/spaceman/database \
  connectionstring="Data Source=tcp:10.10.80.81,1433;Initial Catalog=WingYip_SRS_Spaceman_Database;User Id=sa;Password=1n9pp2.0@123;TrustServerCertificate=True;Encrypt=False"

vault kv put secret/wingyip-srs/staging/stockcontrol/database \
  connectionstring="Data Source=tcp:10.10.80.81,1433;Initial Catalog=WingYip_SRS_StockControl_Database;User Id=sa;Password=1n9pp2.0@123;TrustServerCertificate=True;Encrypt=False"

# Product Service Configuration
echo "📦 Storing Product Service Secrets..."

vault kv put secret/wingyip-srs/staging/product/services \
  administrationservice="http://10.10.80.77:32333/" \
  productservice="http://10.10.80.77:31085/" \
  spacemanservice="http://10.10.80.77:30800/" \
  stockservice="http://10.10.80.77:30385/" \
  orderservice="http://10.10.80.77:32500/" \
  auditservice="http://10.10.80.77:31111/" \
  notificationservice="http://10.10.80.77:32600/"

vault kv put secret/wingyip-srs/staging/product/elasticsearch \
  url="http://10.10.80.77:32000/" \
  numberoreshards="1" \
  numberofreplicas="0"

# RabbitMQ Credentials (Shared)
echo "🐰 Storing RabbitMQ Secrets..."

vault kv put secret/wingyip-srs/staging/shared/rabbitmq \
  hostname="10.10.80.77" \
  port="32210" \
  username="admin" \
  password="RabbitMQ@2025"

# Active Directory Credentials (Shared)
echo "👤 Storing Active Directory Secrets..."

vault kv put secret/wingyip-srs/staging/shared/activedirectory \
  binduser="Administrator@inapp.com" \
  password="admin@123" \
  userprincipalname="Administrator" \
  username="Administrator@inapp.com"

# Keycloak Credentials
echo "🔑 Storing Keycloak Secrets..."

vault kv put secret/wingyip-srs/staging/authentication/keycloak \
  clientsecretweb="rOkAvgIuGrfTbkvBi48IUXGzV50pvZNa" \
  clientsecretmobile="eWtwZ2sVf1H8V53SXjbpnzJbDujMhmlP" \
  adminusername="superadmin" \
  adminpassword="zxcqweq123s"

echo ""
echo "✅ All staging secrets stored successfully in Vault!"
echo ""
echo "📋 Secrets stored at:"
echo "  - secret/wingyip-srs/staging/*/database"
echo "  - secret/wingyip-srs/staging/shared/rabbitmq"
echo "  - secret/wingyip-srs/staging/shared/activedirectory"
echo "  - secret/wingyip-srs/staging/authentication/keycloak"
