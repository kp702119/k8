# Complete CI/CD Pipeline for Kubernetes

This directory contains a complete CI/CD pipeline implementation with HashiCorp Vault, Jenkins, Harbor, ArgoCD, and a sample application.

## 🏗️ Architecture Overview

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  HashiCorp      │  │     Jenkins     │  │     Harbor      │
│     Vault       │  │   CI/CD Server  │  │   Container     │
│ Secret Mgmt     │  │                 │  │   Registry      │
│ :30820         │  │     :30180      │  │    :30280       │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│     ArgoCD      │  │  Sample Node.js │  │   Kubernetes    │
│   GitOps        │  │   Application   │  │    Cluster      │
│   Engine        │  │                 │  │ k8s-master +    │
│    :30443       │  │     :30300      │  │ 2 worker nodes  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## 🎯 CI/CD Pipeline Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Developer  │    │   Jenkins   │    │   Harbor    │    │   ArgoCD    │
│Commits Code │───▶│ Build&Test  │───▶│Store Image  │───▶│Deploy to K8s│
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
      │                    │                   │                  │
      └────────────────────┼───────────────────┼──────────────────┘
                           ▼                   ▼                  ▼
                    ┌─────────────────────────────────────────────────┐
                    │        Sample App Running on Kubernetes         │
                    │           http://10.10.80.76:30300            │
                    └─────────────────────────────────────────────────┘
```

## 📁 Directory Structure

```
cicd/
├── vault/
│   ├── vault-deployment.yaml
│   ├── vault-setup.sh
│   └── deploy-vault.sh
├── jenkins/
│   ├── jenkins-deployment.yaml
│   ├── Jenkinsfile
│   ├── setup-jenkins-job.sh
│   └── deploy-jenkins.sh
├── harbor/
│   ├── harbor-deployment.yaml
│   ├── setup-harbor-projects.sh
│   └── deploy-harbor.sh
├── argocd/
│   ├── argocd-crds.yaml
│   ├── argocd-rbac.yaml
│   ├── argocd-configmaps.yaml
│   ├── argocd-secrets.yaml
│   ├── argocd-core-deployment.yaml
│   ├── argocd-services.yaml
│   ├── setup-argocd-app.sh
│   └── deploy-argocd.sh
├── sample-app/
│   ├── sample-app-deployment.yaml
│   └── deploy-sample-app.sh
├── deploy-all-cicd.sh
├── deploy-pipeline-complete.sh
└── README.md
```

## 🚀 Quick Deployment Commands

### Option 1: Complete Pipeline Deployment (Recommended)
```bash
cd /home/kp/oraganization-project/k8-cluster/cicd
chmod +x deploy-pipeline-complete.sh
./deploy-pipeline-complete.sh
```

### Option 2: All CI/CD Infrastructure Only
```bash
cd /home/kp/oraganization-project/k8-cluster/cicd
chmod +x deploy-all-cicd.sh
./deploy-all-cicd.sh
```

### Option 3: Individual Component Deployment

#### 1. Prerequisites - Create Storage Directories
```bash
ssh root@10.10.80.77 "mkdir -p /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry} && chmod 777 /mnt/local-storage/*"
ssh root@10.10.80.78 "mkdir -p /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry} && chmod 777 /mnt/local-storage/*"
```

#### 2. Deploy HashiCorp Vault
```bash
# Using Script
cd vault && chmod +x deploy-vault.sh && ./deploy-vault.sh

# Using YAML Only
kubectl apply -f vault/vault-deployment.yaml
kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=300s
cd vault && chmod +x vault-setup.sh && ./vault-setup.sh
```

#### 3. Deploy Jenkins
```bash
# Using Script  
cd jenkins && chmod +x deploy-jenkins.sh && ./deploy-jenkins.sh

# Using YAML Only
kubectl apply -f jenkins/jenkins-deployment.yaml
kubectl wait --for=condition=ready pod -l app=jenkins -n cicd --timeout=600s
```

#### 4. Deploy Harbor
```bash
# Using Script
cd harbor && chmod +x deploy-harbor.sh && ./deploy-harbor.sh

# Using YAML Only
kubectl apply -f harbor/harbor-deployment.yaml
kubectl wait --for=condition=ready pod -l app=harbor-database -n harbor --timeout=300s
kubectl wait --for=condition=ready pod -l app=harbor-core -n harbor --timeout=600s
```

#### 5. Deploy ArgoCD
```bash
# Using Script
cd argocd && chmod +x deploy-argocd.sh && ./deploy-argocd.sh

# Using YAML Only (Pure Kubernetes)
kubectl apply -f argocd/argocd-crds.yaml
kubectl apply -f argocd/argocd-rbac.yaml
kubectl apply -f argocd/argocd-configmaps.yaml
kubectl apply -f argocd/argocd-secrets.yaml
kubectl apply -f argocd/argocd-core-deployment.yaml
kubectl apply -f argocd/argocd-services.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s
```

#### 6. Deploy Sample Application
```bash
# Using Script
cd sample-app && chmod +x deploy-sample-app.sh && ./deploy-sample-app.sh

# Using YAML Only
kubectl apply -f sample-app/sample-app-deployment.yaml
kubectl wait --for=condition=ready pod -l app=sample-nodejs-app -n sample-app --timeout=300s
```

### Option 4: Complete Manual YAML Deployment
```bash
# Deploy everything with pure kubectl commands
cd /home/kp/oraganization-project/k8-cluster/cicd

# 1. Create storage directories first
ssh root@10.10.80.77 "mkdir -p /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry} && chmod 777 /mnt/local-storage/*"
ssh root@10.10.80.78 "mkdir -p /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry} && chmod 777 /mnt/local-storage/*"

# 2. Deploy Vault
kubectl apply -f vault/vault-deployment.yaml

# 3. Deploy Jenkins
kubectl apply -f jenkins/jenkins-deployment.yaml

# 4. Deploy Harbor
kubectl apply -f harbor/harbor-deployment.yaml

# 5. Deploy ArgoCD
kubectl apply -f argocd/argocd-crds.yaml
kubectl apply -f argocd/argocd-rbac.yaml
kubectl apply -f argocd/argocd-configmaps.yaml
kubectl apply -f argocd/argocd-secrets.yaml
kubectl apply -f argocd/argocd-core-deployment.yaml
kubectl apply -f argocd/argocd-services.yaml

# 6. Deploy Sample Application
kubectl apply -f sample-app/sample-app-deployment.yaml

# 7. Wait for all deployments
kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=300s
kubectl wait --for=condition=ready pod -l app=jenkins -n cicd --timeout=600s
kubectl wait --for=condition=ready pod -l app=harbor-core -n harbor --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s
kubectl wait --for=condition=ready pod -l app=sample-nodejs-app -n sample-app --timeout=300s
```

## 🌐 Access Information

### HashiCorp Vault
- **URL**: http://10.10.80.76:30820
- **UI**: http://10.10.80.76:30820/ui
- **Root Token**: `vault-root-token-2025`

### Jenkins CI/CD Server
- **URL**: http://10.10.80.76:30180
- **Username**: admin
- **Password**: JenkinsAdmin@2025!

### Harbor Container Registry
- **URL**: http://10.10.80.76:30280
- **Username**: admin
- **Password**: HarborAdmin@2025!

### ArgoCD GitOps Engine
- **URL**: http://10.10.80.76:30443
- **Username**: admin  
- **Password**: ArgoCD@2025!

### Sample Application
- **Main URL**: http://10.10.80.76:30300
- **Health Check**: http://10.10.80.76:30300/health
- **API Info**: http://10.10.80.76:30300/api/info

### Existing Infrastructure
- **Grafana**: http://10.10.80.77:31000 (admin/ProD@Grafan@2025!)
- **Keycloak**: http://10.10.80.76:31080 (admin/KeycloakAdmin@2025!)

## 🔐 Vault Secret Management

The HashiCorp Vault contains the following secret paths:

- `secret/jenkins` - Jenkins CI/CD secrets
- `secret/harbor` - Harbor registry secrets
- `secret/argocd` - ArgoCD GitOps secrets
- `secret/database` - Database passwords
- `secret/keycloak` - Keycloak identity secrets
- `secret/monitoring` - Monitoring stack secrets
- `secret/sample-app` - Sample application secrets
- `secret/tls` - SSL/TLS certificates

### Vault Usage Examples
```bash
# Access Vault CLI (from a pod with vault client)
vault kv get secret/jenkins
vault kv put secret/myapp key=value
vault kv delete secret/myapp
```

## � CI/CD Pipeline Setup

### Jenkins Pipeline Configuration
1. **Access Jenkins**: http://10.10.80.76:30180 (admin/JenkinsAdmin@2025!)
2. **Add Harbor Credentials**:
   ```bash
   # Go to Jenkins → Manage Jenkins → Manage Credentials
   # Add Username/Password Credential:
   # ID: harbor-credentials
   # Username: admin
   # Password: HarborAdmin@2025!
   ```
3. **Create Pipeline Job**:
   - New Item → Pipeline → Name: `sample-app-cicd`
   - Copy pipeline script from: `jenkins/Jenkinsfile`
   - Save and Build Now

### Harbor Registry Setup
```bash
# Setup Harbor projects
cd harbor && chmod +x setup-harbor-projects.sh && ./setup-harbor-projects.sh

# Manual Harbor project creation
curl -X POST "http://10.10.80.76:30280/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -u "admin:HarborAdmin@2025!" \
  -d '{"project_name": "sample-app", "public": true}'
```

### ArgoCD Application Setup
```bash
# Setup ArgoCD application
cd argocd && chmod +x setup-argocd-app.sh && ./setup-argocd-app.sh

# Manual ArgoCD application creation
kubectl apply -f - << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-nodejs-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/your-username/k8s-manifests.git'
    targetRevision: HEAD
    path: .
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: sample-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## 🛠️ Complete Manual Step-by-Step Deployment

For complete manual control, follow these commands in order:

## 🔍 Verification Commands

### Check All Deployments
```bash
# Check pods status
kubectl get pods --all-namespaces | grep -E "(vault|cicd|harbor|argocd|sample-app)"

# Check services
kubectl get svc --all-namespaces | grep -E "(vault|jenkins|harbor|argocd|sample-app)"

# Check persistent volumes
kubectl get pv | grep -E "(vault|jenkins|harbor)"
```

### Test Sample Application
```bash
# Test main endpoint
curl http://10.10.80.76:30300

# Test health endpoint
curl http://10.10.80.76:30300/health

# Test info endpoint
curl http://10.10.80.76:30300/api/info
```

## 🧹 Cleanup Commands

### Remove All CI/CD Components
```bash
# Delete sample app
kubectl delete namespace sample-app

# Delete ArgoCD
kubectl delete namespace argocd

# Delete Harbor
kubectl delete namespace harbor

# Delete Jenkins
kubectl delete namespace cicd

# Delete Vault
kubectl delete namespace vault

# Clean up persistent volumes
kubectl delete pv vault-storage-pv jenkins-pv harbor-db-pv harbor-registry-pv
```

### Remove Storage Directories
```bash
ssh root@10.10.80.77 "rm -rf /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry}"
ssh root@10.10.80.78 "rm -rf /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry}"
```

## 📝 Quick Reference Commands

### Check All Deployments
```bash
# Check all namespaces
kubectl get pods --all-namespaces | grep -E "(vault|cicd|harbor|argocd|sample-app)"

# Check services
kubectl get svc --all-namespaces | grep -E "(vault|jenkins|harbor|argocd|sample-app)"

# Check persistent volumes
kubectl get pv | grep -E "(vault|jenkins|harbor)"
```

### Access All Services
```bash
# Test all endpoints
curl http://10.10.80.76:30820/v1/sys/health        # Vault
curl http://10.10.80.76:30180/login               # Jenkins  
curl http://10.10.80.76:30280/api/v2.0/systeminfo # Harbor
curl http://10.10.80.76:30443/api/version         # ArgoCD
curl http://10.10.80.76:30300/health              # Sample App
```

### Common Troubleshooting
```bash
# Check pod logs
kubectl logs -n vault deployment/vault
kubectl logs -n cicd deployment/jenkins  
kubectl logs -n harbor deployment/harbor-core
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n sample-app deployment/sample-nodejs-app

# Restart deployments
kubectl rollout restart deployment/vault -n vault
kubectl rollout restart deployment/jenkins -n cicd
kubectl rollout restart deployment/harbor-core -n harbor
kubectl rollout restart deployment/argocd-server -n argocd
kubectl rollout restart deployment/sample-nodejs-app -n sample-app

# Check resource usage
kubectl top pods --all-namespaces | grep -E "(vault|cicd|harbor|argocd|sample-app)"
kubectl top nodes
```

## 🚀 CI/CD Pipeline Workflow

### Complete Pipeline Execution
1. **Developer commits code** to Git repository
2. **Jenkins webhook triggered** → Builds code → Runs tests
3. **Docker image built** and pushed to Harbor registry  
4. **ArgoCD detects changes** → Syncs with Git → Deploys to Kubernetes
5. **Application running** on http://10.10.80.76:30300

### Manual Pipeline Trigger
```bash
# Trigger Jenkins build manually
curl -X POST 'http://10.10.80.76:30180/job/sample-app-cicd/build' \
  --user 'admin:JenkinsAdmin@2025!'

# Force ArgoCD sync
kubectl patch app sample-nodejs-app -n argocd --type merge -p='{"operation":{"sync":{"revision":"HEAD"}}}'

# Check application status
kubectl get applications -n argocd
kubectl describe application sample-nodejs-app -n argocd
```

## 📚 Next Steps

1. **Configure Jenkins Pipelines**: Set up CI/CD pipelines in Jenkins
2. **Create Harbor Projects**: Organize container images in Harbor  
3. **Setup ArgoCD Applications**: Configure GitOps deployments
4. **Integrate with Vault**: Use Vault secrets in your applications
5. **Connect to Existing Monitoring**: Integrate with Grafana/Prometheus
6. **Configure Keycloak Integration**: Set up SSO for all services

## 🆘 Troubleshooting

### Common Issues

1. **Pod Stuck in Pending**: Check storage directories and node labels
2. **Vault Secrets Not Working**: Ensure Vault is initialized and unsealed  
3. **ArgoCD Password**: Default password is `ArgoCD@2025!` or get from secret:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```
4. **Storage Issues**: Verify `/mnt/local-storage/` directories exist and have correct permissions
5. **FIPS Mode Issues**: If seeing crypto/ecdh errors, use the manual YAML deployment approach

### Debug Commands
```bash
# Check pod logs
kubectl logs -n vault deployment/vault
kubectl logs -n cicd deployment/jenkins
kubectl logs -n harbor deployment/harbor-core  
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n sample-app deployment/sample-nodejs-app

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check resource constraints
kubectl describe nodes
kubectl top nodes
kubectl top pods --all-namespaces
```

## 🎯 Deployment Summary

### Single Command Deployment (Fastest)
```bash
cd /home/kp/oraganization-project/k8-cluster/cicd
./deploy-pipeline-complete.sh
```

### Pure YAML Deployment (Most Reliable)  
```bash
cd /home/kp/oraganization-project/k8-cluster/cicd

# 1. Storage setup
ssh root@10.10.80.77 "mkdir -p /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry} && chmod 777 /mnt/local-storage/*"
ssh root@10.10.80.78 "mkdir -p /mnt/local-storage/{vault,jenkins,harbor-db,harbor-registry} && chmod 777 /mnt/local-storage/*"

# 2. Deploy all components
kubectl apply -f vault/vault-deployment.yaml
kubectl apply -f jenkins/jenkins-deployment.yaml  
kubectl apply -f harbor/harbor-deployment.yaml
kubectl apply -f argocd/argocd-crds.yaml
kubectl apply -f argocd/argocd-rbac.yaml
kubectl apply -f argocd/argocd-configmaps.yaml
kubectl apply -f argocd/argocd-secrets.yaml
kubectl apply -f argocd/argocd-core-deployment.yaml
kubectl apply -f argocd/argocd-services.yaml
kubectl apply -f sample-app/sample-app-deployment.yaml

# 3. Wait for ready
kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=300s
kubectl wait --for=condition=ready pod -l app=jenkins -n cicd --timeout=600s
kubectl wait --for=condition=ready pod -l app=harbor-core -n harbor --timeout=600s  
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s
kubectl wait --for=condition=ready pod -l app=sample-nodejs-app -n sample-app --timeout=300s
```

### Final Access URLs
- **🔐 Vault**: http://10.10.80.76:30820 (vault-root-token-2025)
- **🔧 Jenkins**: http://10.10.80.76:30180 (admin/JenkinsAdmin@2025!)  
- **🐳 Harbor**: http://10.10.80.76:30280 (admin/HarborAdmin@2025!)
- **🚀 ArgoCD**: http://10.10.80.76:30443 (admin/ArgoCD@2025!)
- **📱 Sample App**: http://10.10.80.76:30300
- **📊 Grafana**: http://10.10.80.77:31000 (existing)
- **🔐 Keycloak**: http://10.10.80.76:31080 (existing)

---

**🎉 Complete CI/CD Pipeline Ready! Happy DevOps-ing! 🚀**