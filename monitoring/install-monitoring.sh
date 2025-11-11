#!/bin/bash
# Installation script for Prometheus and Grafana monitoring stack
# Run this on the Kubernetes master node (10.10.80.76)

set -e

echo "🚀 Starting Prometheus and Grafana installation..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm not found. Please install helm first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Add Prometheus community repository
echo "📦 Adding Prometheus community Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "🏗️ Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
echo "⚙️ Installing Prometheus and Grafana stack..."
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=5Gi \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=31000 \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=31001 \
  --set alertmanager.service.type=NodePort \
  --set alertmanager.service.nodePort=31002

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=600s

echo "🔍 Checking deployment status..."
kubectl get pods -n monitoring
kubectl get svc -n monitoring

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📊 Access your monitoring services:"
echo "   Grafana:      http://$(hostname -I | awk '{print $1}'):31000"
echo "   Username:     admin"
echo "   Password:     admin123"
echo ""
echo "   Prometheus:   http://$(hostname -I | awk '{print $1}'):31001"
echo "   AlertManager: http://$(hostname -I | awk '{print $1}'):31002"
echo ""
echo "🔧 Alternative access using NodePort:"
GRAFANA_PORT=$(kubectl get svc prometheus-stack-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
PROMETHEUS_PORT=$(kubectl get svc prometheus-stack-kube-prom-prometheus -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
ALERTMANAGER_PORT=$(kubectl get svc prometheus-stack-kube-prom-alertmanager -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')

echo "   Grafana:      http://$(hostname -I | awk '{print $1}'):${GRAFANA_PORT}"
echo "   Prometheus:   http://$(hostname -I | awk '{print $1}'):${PROMETHEUS_PORT}"
echo "   AlertManager: http://$(hostname -I | awk '{print $1}'):${ALERTMANAGER_PORT}"
echo ""
echo "✨ Happy monitoring!"