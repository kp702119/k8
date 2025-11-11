# 🔐 Keycloak Production Setup - Complete Guide

Production-ready Keycloak Identity and Access Management system for Kubernetes cluster with PostgreSQL backend and persistent storage.

## 📋 Overview

- **Keycloak Version**: 23.0.0 (Latest)
- **Database**: PostgreSQL 15 with persistent storage
- **Deployment**: Worker nodes only (production best practice)
- **Access**: NodePort service for direct browser access
- **Storage**: Local persistent volumes with 10GB capacity
- **Security**: Kubernetes secrets for credentials

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   k8s-master    │    │   k8s-node1     │    │   k8s-node2     │
│  (10.10.80.76)  │    │  (10.10.80.77)  │    │  (10.10.80.78)  │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ ✅ Control Plane │    │ ✅ PostgreSQL   │    │ ✅ Keycloak     │
│ ✅ Access Point │    │ ✅ Persistent   │    │ ✅ Worker Apps  │
│                 │    │    Storage      │    │                 │
│ ❌ NO Workloads │    │ 🗄️ Database     │    │ 🔐 Identity    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Files Structure

```
keycloak/
├── README.md                    # This documentation
├── 1-storage-setup.yaml         # StorageClass and PersistentVolume
├── 2-keycloak-production.yaml   # Complete Keycloak deployment
└── keycloak-setup-guide.md     # Step-by-step setup guide
```

## 🚀 Quick Installation

### Prerequisites
- Kubernetes cluster with 3 nodes
- Worker nodes labeled: `node-role.kubernetes.io/worker=true`
- Storage directories created on worker nodes

### Installation Steps

1. **Create storage directories on worker nodes**:
   ```bash
   # SSH to k8s-node1
   ssh root@10.10.80.77 "mkdir -p /mnt/local-storage/keycloak-postgres && chmod 777 /mnt/local-storage/keycloak-postgres"
   
   # SSH to k8s-node2  
   ssh root@10.10.80.78 "mkdir -p /mnt/local-storage/keycloak-postgres && chmod 777 /mnt/local-storage/keycloak-postgres"
   ```

2. **Label worker nodes**:
   ```bash
   kubectl label node k8s-node1 node-role.kubernetes.io/worker=true --overwrite
   kubectl label node k8s-node2 node-role.kubernetes.io/worker=true --overwrite
   ```

3. **Deploy storage configuration**:
   ```bash
   kubectl apply -f 1-storage-setup.yaml
   kubectl get storageclass
   kubectl get pv
   ```

4. **Deploy Keycloak**:
   ```bash
   kubectl apply -f 2-keycloak-production.yaml
   ```

5. **Monitor deployment**:
   ```bash
   kubectl get pods -n keycloak -w
   kubectl wait --for=condition=ready pod -l app=postgres -n keycloak --timeout=300s
   kubectl wait --for=condition=ready pod -l app=keycloak -n keycloak --timeout=600s
   ```

## 🌐 Access Information

### Browser Access
- **Admin Console**: http://10.10.80.76:31080/admin
- **Main Portal**: http://10.10.80.76:31080
- **Alternative URLs**: 
  - http://10.10.80.77:31080/admin
  - http://10.10.80.78:31080/admin

### Credentials
- **Username**: admin
- **Password**: KeycloakAdmin@2025!

### Service Information
```bash
# Get service details
kubectl get svc -n keycloak

# Get exact NodePort
kubectl get svc keycloak-service -n keycloak -o jsonpath='{.spec.ports[0].nodePort}'
```

## 🔧 Management Commands

### Check Status
```bash
# Check all resources
kubectl get all -n keycloak

# Check pods with node placement
kubectl get pods -n keycloak -o wide

# Check persistent storage
kubectl get pvc -n keycloak
kubectl get pv
```

### View Logs
```bash
# Keycloak logs
kubectl logs -l app=keycloak -n keycloak -f

# PostgreSQL logs
kubectl logs -l app=postgres -n keycloak
```

### Scaling and Updates
```bash
# Scale Keycloak (if needed)
kubectl scale deployment keycloak -n keycloak --replicas=2

# Restart deployment
kubectl rollout restart deployment keycloak -n keycloak

# Check rollout status
kubectl rollout status deployment keycloak -n keycloak
```

## 🔒 Security Features

- ✅ **Non-root containers**: Security contexts configured
- ✅ **Kubernetes secrets**: Passwords stored securely
- ✅ **Resource limits**: CPU and memory constraints
- ✅ **Network isolation**: Namespace-based separation
- ✅ **Persistent storage**: Data survives pod restarts
- ✅ **Worker node deployment**: Master node protection

## 📊 Production Features

- ✅ **High availability ready**: Can scale to multiple replicas
- ✅ **Database persistence**: PostgreSQL with 10GB storage
- ✅ **Health checks**: Readiness and liveness probes
- ✅ **Resource management**: CPU/memory requests and limits
- ✅ **Development mode**: Easy configuration and debugging
- ✅ **Multi-node access**: Available on all cluster nodes

## 🛠️ Troubleshooting

### Common Issues

**Pod not starting**:
```bash
kubectl describe pod -l app=keycloak -n keycloak
kubectl logs -l app=keycloak -n keycloak
```

**Storage issues**:
```bash
kubectl get pvc -n keycloak
kubectl describe pvc postgres-pvc -n keycloak
```

**Network connectivity**:
```bash
kubectl exec -it deployment/keycloak -n keycloak -- nslookup postgres-service
curl http://10.10.80.76:31080/
```

### Reset Deployment
```bash
# Clean up
kubectl delete namespace keycloak
kubectl delete pv keycloak-postgres-pv

# Redeploy
kubectl apply -f 1-storage-setup.yaml
kubectl apply -f 2-keycloak-production.yaml
```

## 🔄 Backup and Recovery

### Database Backup
```bash
# Create backup
kubectl exec -it deployment/postgres -n keycloak -- pg_dump -U keycloak keycloak > keycloak-backup-$(date +%Y%m%d).sql

# Restore backup
kubectl exec -i deployment/postgres -n keycloak -- psql -U keycloak keycloak < keycloak-backup-YYYYMMDD.sql
```

### Configuration Backup
```bash
# Backup Kubernetes resources
kubectl get all -n keycloak -o yaml > keycloak-k8s-backup.yaml

# Backup secrets
kubectl get secrets -n keycloak -o yaml > keycloak-secrets-backup.yaml
```

## 📈 Next Steps

1. **Initial Configuration**:
   - Login to admin console
   - Create your organization realm
   - Configure authentication policies

2. **User Management**:
   - Create user accounts
   - Set up groups and roles  
   - Configure password policies

3. **Integration**:
   - Configure client applications
   - Set up SSO for services
   - Integrate with Kubernetes RBAC

4. **Production Hardening**:
   - Configure SSL certificates
   - Set up proper DNS
   - Enable monitoring and alerting

## 📞 Support

- **Keycloak Documentation**: https://www.keycloak.org/documentation
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Kubernetes Documentation**: https://kubernetes.io/docs/

---

**✅ Production-Ready Keycloak Identity Management System**

Your Keycloak deployment follows production best practices with persistent storage, security configurations, and proper node placement. Ready for enterprise use!