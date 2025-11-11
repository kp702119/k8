# Sample CI/CD Application

This is a sample Node.js application demonstrating a complete CI/CD pipeline using:
- **GitHub** - Source code repository
- **Jenkins** - CI/CD automation
- **Harbor** - Container registry
- **ArgoCD** - GitOps deployment
- **Vault** - Secrets management
- **Kubernetes** - Container orchestration

## Architecture

```
Developer → GitHub → Jenkins → Harbor → GitOps Repo → ArgoCD → Kubernetes
```

## Setup Instructions

### 1. Push this code to GitHub

```bash
cd sample-cicd-app
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR-USERNAME/sample-cicd-app.git
git push -u origin main
```

### 2. Create GitOps Repository

Create a separate repository for Kubernetes manifests and add the deployment files (see gitops-manifests/ directory).

### 3. Configure Jenkins

1. Login to Jenkins: http://10.10.80.77:30180
2. Create new Pipeline job named: `sample-cicd-app`
3. Configure:
   - Pipeline from SCM
   - Git: https://github.com/YOUR-USERNAME/sample-cicd-app.git
   - Credentials: github-token
   - Script Path: Jenkinsfile

### 4. Add Credentials in Jenkins

- **github-token**: Your GitHub personal access token
- **harbor-credentials**: admin / Harbor12345

### 5. Configure GitHub Webhook

- Payload URL: http://10.10.80.77:30180/github-webhook/
- Content type: application/json
- Events: Just the push event

### 6. Create ArgoCD Application

```bash
argocd app create sample-cicd-app \
  --repo https://github.com/YOUR-USERNAME/gitops-repo.git \
  --path sample-cicd-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production \
  --sync-policy automated
```

### 7. Deploy

Push code changes to trigger the pipeline:

```bash
git add .
git commit -m "Deploy application"
git push origin main
```

## Testing

### Local Development

```bash
npm install
npm start
```

Access at: http://localhost:3000

### Test Endpoints

- `GET /` - Application info
- `GET /health` - Health check
- `GET /api/info` - Pipeline info

### After Deployment

```bash
# Check pods
kubectl get pods -n production

# Check service
kubectl get svc -n production

# Test application
curl http://10.10.80.77:30500
```

## Pipeline Workflow

1. **Commit & Push** → GitHub receives code
2. **Webhook** → Jenkins pipeline triggered
3. **Build** → Docker image created
4. **Test** → Automated tests run
5. **Push** → Image pushed to Harbor
6. **Update** → GitOps repo updated with new image tag
7. **Deploy** → ArgoCD detects change and deploys to Kubernetes

## Monitoring

- **Jenkins**: http://10.10.80.77:30180
- **Harbor**: http://10.10.80.77:30280
- **ArgoCD**: http://10.10.80.77:30443
- **Application**: http://10.10.80.77:30500

## Credentials

- Jenkins: admin / vqRBOBYOUc2ci8ZltqTqbi
- Harbor: admin / Harbor12345
- ArgoCD: admin / jLvTCOHb-wfNeGE2

## Troubleshooting

### Build fails in Jenkins
- Check Jenkins logs: `kubectl logs -n cicd jenkins-0 -c jenkins`
- Verify credentials are configured
- Check Docker daemon in Jenkins pod

### Image not in Harbor
- Verify Harbor credentials
- Check network connectivity
- Review Jenkins build logs

### ArgoCD not deploying
- Verify GitOps repo is updated
- Check ArgoCD application status: `argocd app get sample-cicd-app`
- Force sync: `argocd app sync sample-cicd-app`

### Application not accessible
- Check pods: `kubectl get pods -n production`
- Check service: `kubectl get svc -n production`
- View logs: `kubectl logs -n production -l app=sample-cicd-app`

## Next Steps

1. Add more comprehensive tests
2. Implement staging environment
3. Add monitoring with Prometheus/Grafana
4. Integrate Vault for secrets
5. Add deployment strategies (blue-green, canary)

## License

MIT
