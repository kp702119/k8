#!/bin/bash

# CI/CD Pipeline Quick Start Script
# This script helps set up the complete CI/CD pipeline

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        CI/CD Pipeline Quick Start Setup                       ║"
echo "║  Jenkins → Harbor → ArgoCD → Kubernetes                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="production"
HARBOR_URL="10.10.80.77:30280"
HARBOR_USER="admin"
HARBOR_PASS="Harbor12345"
ARGOCD_SERVER="10.10.80.77:30443"
ARGOCD_USER="admin"
ARGOCD_PASS="jLvTCOHb-wfNeGE2"

echo -e "${BLUE}Step 1: Creating production namespace...${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

echo -e "${BLUE}Step 2: Creating Harbor registry credentials...${NC}"
kubectl create secret docker-registry harbor-credentials \
  --docker-server=${HARBOR_URL} \
  --docker-username=${HARBOR_USER} \
  --docker-password=${HARBOR_PASS} \
  --docker-email=admin@example.com \
  -n ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Harbor credentials created${NC}"
echo ""

echo -e "${BLUE}Step 3: Checking ArgoCD installation...${NC}"
if kubectl get pods -n cicd -l app.kubernetes.io/name=argocd-server &>/dev/null; then
    echo -e "${GREEN}✓ ArgoCD is running${NC}"
else
    echo -e "${RED}✗ ArgoCD not found${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 4: Verifying Harbor...${NC}"
if curl -s http://${HARBOR_URL}/api/v2.0/systeminfo &>/dev/null; then
    echo -e "${GREEN}✓ Harbor is accessible${NC}"
else
    echo -e "${RED}✗ Harbor not accessible${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 5: Verifying Jenkins...${NC}"
if curl -s http://10.10.80.77:30180 &>/dev/null; then
    echo -e "${GREEN}✓ Jenkins is accessible${NC}"
else
    echo -e "${RED}✗ Jenkins not accessible${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Infrastructure Setup Complete!${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Create GitHub Repositories:"
echo "   - Application repo: sample-cicd-app"
echo "   - GitOps repo: gitops-repo"
echo ""

echo "2. Push Application Code:"
echo "   ${YELLOW}cd sample-cicd-app${NC}"
echo "   ${YELLOW}git init${NC}"
echo "   ${YELLOW}git add .${NC}"
echo "   ${YELLOW}git commit -m 'Initial commit'${NC}"
echo "   ${YELLOW}git remote add origin https://github.com/YOUR-USERNAME/sample-cicd-app.git${NC}"
echo "   ${YELLOW}git push -u origin main${NC}"
echo ""

echo "3. Push GitOps Manifests:"
echo "   ${YELLOW}cd gitops-manifests${NC}"
echo "   ${YELLOW}git init${NC}"
echo "   ${YELLOW}git add .${NC}"
echo "   ${YELLOW}git commit -m 'Initial manifests'${NC}"
echo "   ${YELLOW}git remote add origin https://github.com/YOUR-USERNAME/gitops-repo.git${NC}"
echo "   ${YELLOW}git push -u origin main${NC}"
echo ""

echo "4. Configure Jenkins:"
echo "   - URL: ${YELLOW}http://10.10.80.77:30180${NC}"
echo "   - Username: ${YELLOW}admin${NC}"
echo "   - Password: ${YELLOW}vqRBOBYOUc2ci8ZltqTqbi${NC}"
echo "   - Create Pipeline Job: sample-cicd-app"
echo "   - Add Credentials: github-token, harbor-credentials"
echo ""

echo "5. Configure ArgoCD Application:"
echo "   ${YELLOW}argocd login ${ARGOCD_SERVER} --insecure --username ${ARGOCD_USER} --password ${ARGOCD_PASS}${NC}"
echo "   ${YELLOW}argocd repo add https://github.com/YOUR-USERNAME/gitops-repo.git${NC}"
echo "   ${YELLOW}argocd app create sample-cicd-app \\${NC}"
echo "   ${YELLOW}  --repo https://github.com/YOUR-USERNAME/gitops-repo.git \\${NC}"
echo "   ${YELLOW}  --path sample-cicd-app \\${NC}"
echo "   ${YELLOW}  --dest-server https://kubernetes.default.svc \\${NC}"
echo "   ${YELLOW}  --dest-namespace ${NAMESPACE} \\${NC}"
echo "   ${YELLOW}  --sync-policy automated${NC}"
echo ""

echo "6. Set up GitHub Webhook:"
echo "   - Repository Settings → Webhooks → Add webhook"
echo "   - URL: ${YELLOW}http://10.10.80.77:30180/github-webhook/${NC}"
echo "   - Content type: application/json"
echo "   - Events: Just the push event"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Access URLs:${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "Jenkins:  ${BLUE}http://10.10.80.77:30180${NC}"
echo -e "Harbor:   ${BLUE}http://10.10.80.77:30280${NC}"
echo -e "ArgoCD:   ${BLUE}http://10.10.80.77:30443${NC}"
echo -e "Vault:    ${BLUE}http://10.10.80.77:30820${NC}"
echo -e "Your App: ${BLUE}http://10.10.80.77:30500${NC} (after deployment)"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}For complete documentation, see:${NC}"
echo "  - CICD-PIPELINE-SETUP-GUIDE.txt"
echo "  - sample-cicd-app/README.md"
echo "  - gitops-manifests/README.md"
echo ""

echo -e "${GREEN}Setup complete! Follow the steps above to deploy your application.${NC}"
