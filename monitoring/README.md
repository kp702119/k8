# Kubernetes Monitoring Stack

This directory contains all configuration and setup files for monitoring your Kubernetes cluster with Prometheus and Grafana.

## 📁 Files Overview

### 🚀 Quick Start
- **`install-monitoring.sh`** - Automated installation script (run this first!)
- **`prometheus-grafana-setup.txt`** - Complete setup guide with detailed instructions

### ⚙️ Configuration Files
- **`monitoring-values.yaml`** - Helm values for custom configuration
- **`monitoring-ingress.yaml`** - Ingress configuration for web access

## 🎯 Production Installation (RECOMMENDED)

1. **Run the PRODUCTION installer (deploys on worker nodes only):**
   ```bash
   cd /home/kp/oraganization-project/k8-cluster/monitoring
   ./install-production-monitoring.sh
   ```

2. **Production Access:**
   - **Grafana**: https://grafana.k8s.local (admin/ProD@Grafan@2025!)
   - **Prometheus**: https://prometheus.k8s.local
   - **AlertManager**: https://alertmanager.k8s.local

## 🔧 Development Installation (Basic)

1. **Run the basic installer (NOT for production):**
   ```bash
   cd /home/kp/oraganization-project/k8-cluster/monitoring
   ./install-monitoring.sh
   ```

2. **Development Access:**
   - **Grafana**: http://10.10.80.77:31000 (admin/admin123)
   - **Prometheus**: http://10.10.80.77:31001
   - **AlertManager**: http://10.10.80.77:31002

## 📊 What You Get

### Grafana Dashboards
- Kubernetes cluster overview
- Node resource monitoring
- Pod and container metrics
- Network and storage monitoring
- Custom alerting rules

### Prometheus Metrics
- Cluster-wide metrics collection
- Application performance monitoring
- Infrastructure monitoring
- Custom metrics support

### AlertManager
- Intelligent alert routing
- Notification management
- Alert silencing and grouping
- Integration with external systems

## 🔧 Advanced Configuration

### Custom Monitoring
To monitor custom applications:
1. Create ServiceMonitor resources
2. Expose `/metrics` endpoints
3. Configure Grafana dashboards

### Ingress Access
Apply ingress configuration for hostname-based access:
```bash
kubectl apply -f monitoring-ingress.yaml
```

Add to your `/etc/hosts`:
```
10.10.80.76 grafana.local.cluster
10.10.80.76 prometheus.local.cluster
10.10.80.76 alertmanager.local.cluster
```

## 📖 Documentation

- **Complete Guide**: `prometheus-grafana-setup.txt`
- **Main Setup Guide**: `../kubernetes-rancher-complete-setup-guide.txt` (Section 6)

## 🆘 Support

If you encounter issues:
1. Check pod status: `kubectl get pods -n monitoring`
2. View logs: `kubectl logs -n monitoring -l app.kubernetes.io/name=grafana`
3. Verify services: `kubectl get svc -n monitoring`

## ✅ Verification Checklist

- [ ] All monitoring pods are running
- [ ] Grafana is accessible via web browser
- [ ] Prometheus is collecting metrics
- [ ] AlertManager is configured
- [ ] Pre-built dashboards are working
- [ ] Node metrics are visible

---
**Created**: November 4, 2025  
**Cluster**: k8s-master (10.10.80.76), k8s-node1 (10.10.80.77), k8s-node2 (10.10.80.78)