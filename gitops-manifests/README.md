# GitOps Repository for Kubernetes Manifests

This repository contains Kubernetes manifests managed by ArgoCD for GitOps deployments.

## Structure

```
gitops-manifests/
└── sample-cicd-app/
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

## Setup

### 1. Create GitHub Repository

```bash
cd gitops-manifests
git init
git add .
git commit -m "Initial GitOps manifests"
git remote add origin https://github.com/YOUR-USERNAME/gitops-repo.git
git push -u origin main
```

### 2. Create Harbor Credentials Secret

```bash
kubectl create namespace production

kubectl create secret docker-registry harbor-credentials \
  --docker-server=10.10.80.77:30280 \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  --docker-email=admin@example.com \
  -n production
```

### 3. Configure ArgoCD

#### Option 1: Using ArgoCD CLI

```bash
# Login to ArgoCD
argocd login 10.10.80.77:30443 --insecure \
  --username admin \
  --password jLvTCOHb-wfNeGE2

# Add repository (if private)
argocd repo add https://github.com/YOUR-USERNAME/gitops-repo.git \
  --username YOUR-USERNAME \
  --password YOUR-GITHUB-TOKEN

# Create application
argocd app create sample-cicd-app \
  --repo https://github.com/YOUR-USERNAME/gitops-repo.git \
  --path sample-cicd-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Verify
argocd app list
argocd app get sample-cicd-app
```

#### Option 2: Using Kubernetes Manifest

Create `argocd-application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-cicd-app
  namespace: cicd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR-USERNAME/gitops-repo.git
    targetRevision: HEAD
    path: sample-cicd-app
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

Apply:
```bash
kubectl apply -f argocd-application.yaml
```

## How It Works

1. **Jenkins builds** → Pushes new image to Harbor with build number tag
2. **Jenkins updates** → Modifies `deployment.yaml` with new image tag
3. **ArgoCD detects** → Sees change in Git repository
4. **ArgoCD syncs** → Applies updated manifests to Kubernetes
5. **Kubernetes deploys** → Rolling update with new image

## Manual Deployment

If needed, you can deploy manually:

```bash
kubectl apply -f sample-cicd-app/namespace.yaml
kubectl apply -f sample-cicd-app/deployment.yaml
kubectl apply -f sample-cicd-app/service.yaml
```

## Verify Deployment

```bash
# Check namespace
kubectl get ns production

# Check deployment
kubectl get deployment -n production

# Check pods
kubectl get pods -n production

# Check service
kubectl get svc -n production

# Check application
curl http://10.10.80.77:30500
```

## Update Application

Jenkins will automatically update the image tag in `deployment.yaml`. Example:

```yaml
# Before
image: 10.10.80.77:30280/library/sample-cicd-app:1

# After Jenkins build #5
image: 10.10.80.77:30280/library/sample-cicd-app:5
```

ArgoCD will detect this change and deploy the new version.

## Rollback

### Using ArgoCD

```bash
# View history
argocd app history sample-cicd-app

# Rollback to previous version
argocd app rollback sample-cicd-app <revision-number>
```

### Using Kubernetes

```bash
# Rollback deployment
kubectl rollout undo deployment/sample-cicd-app -n production

# Check rollout status
kubectl rollout status deployment/sample-cicd-app -n production

# View rollout history
kubectl rollout history deployment/sample-cicd-app -n production
```

## Monitoring

### ArgoCD UI
- URL: http://10.10.80.77:30443
- View sync status, health, and history

### Kubernetes
```bash
# Watch pods
kubectl get pods -n production -w

# View logs
kubectl logs -n production -l app=sample-cicd-app -f

# Describe deployment
kubectl describe deployment sample-cicd-app -n production
```

## Troubleshooting

### Application Not Syncing

```bash
# Check ArgoCD application
argocd app get sample-cicd-app

# View sync status
argocd app sync sample-cicd-app --dry-run

# Force sync
argocd app sync sample-cicd-app --force
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n production

# Describe pod
kubectl describe pod -n production <pod-name>

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check if secret exists
kubectl get secret harbor-credentials -n production
```

### Image Pull Errors

```bash
# Verify Harbor credentials
kubectl get secret harbor-credentials -n production -o yaml

# Test Harbor login from worker node
docker login 10.10.80.77:30280 -u admin -p Harbor12345

# Recreate secret if needed
kubectl delete secret harbor-credentials -n production
kubectl create secret docker-registry harbor-credentials \
  --docker-server=10.10.80.77:30280 \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  -n production
```

## Best Practices

1. **Never commit secrets** - Use Kubernetes secrets or Vault
2. **Use specific tags** - Avoid `latest` in production
3. **Review changes** - Check diffs before syncing
4. **Test in staging** - Deploy to staging environment first
5. **Monitor deployments** - Watch ArgoCD and Kubernetes events

## Adding More Applications

To add more applications, create a new directory:

```
gitops-manifests/
├── sample-cicd-app/
├── my-other-app/
│   ├── deployment.yaml
│   └── service.yaml
└── my-third-app/
    └── ...
```

Create ArgoCD application for each:

```bash
argocd app create my-other-app \
  --repo https://github.com/YOUR-USERNAME/gitops-repo.git \
  --path my-other-app \
  --dest-namespace production
```

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
