const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from CI/CD Pipeline!',
    application: 'Sample CICD App',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
    hostname: require('os').hostname()
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/info', (req, res) => {
  res.json({
    pipeline: {
      jenkins: 'http://10.10.80.77:30180',
      harbor: 'http://10.10.80.77:30280',
      argocd: 'http://10.10.80.77:30443',
      vault: 'http://10.10.80.77:30820'
    },
    deployment: {
      platform: 'Kubernetes',
      deployed_via: 'ArgoCD GitOps',
      built_by: 'Jenkins CI',
      registry: 'Harbor'
    }
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Application listening on port ${port}`);
  console.log(`📦 Version: ${process.env.APP_VERSION || '1.0.0'}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});
