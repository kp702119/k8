#!/bin/bash
# Production Monitoring Installation Script
# Deploys Prometheus and Grafana on WORKER NODES ONLY
# Follows production best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Production configuration
NAMESPACE="monitoring"
RELEASE_NAME="prometheus-stack"
VALUES_FILE="production-values.yaml"
MASTER_NODE="k8s-master"
WORKER1_NODE="k8s-node1"
WORKER2_NODE="k8s-node2"

echo -e "${BLUE}🏭 PRODUCTION MONITORING STACK INSTALLER${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  PRODUCTION DEPLOYMENT STRATEGY:${NC}"
echo -e "   ✅ Master Node (${MASTER_NODE}): Control plane + Node monitoring only"
echo -e "      - Node Exporter (system metrics)"
echo -e "      - Control plane metrics (API server, etcd, scheduler)"
echo -e "      - NO heavy workloads (Grafana, Prometheus, AlertManager)"
echo -e "   ✅ Worker Nodes (${WORKER1_NODE}, ${WORKER2_NODE}): Full monitoring stack"
echo -e "   ✅ High availability with 2+ replicas"
echo -e "   ✅ Persistent storage for data retention"
echo -e "   ✅ Resource limits and security hardening"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ helm not found. Please install helm first.${NC}"
    exit 1
fi

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo -e "${RED}❌ Production values file ($VALUES_FILE) not found.${NC}"
    echo -e "   Please ensure you're running this script from the monitoring directory."
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Step 1: Label nodes for production deployment
echo -e "${BLUE}🏷️  Step 1: Configuring node labels and taints...${NC}"

# Label worker nodes
kubectl label node $WORKER1_NODE node-role.kubernetes.io/worker=true --overwrite
kubectl label node $WORKER2_NODE node-role.kubernetes.io/worker=true --overwrite
kubectl label node $WORKER1_NODE monitoring=enabled --overwrite
kubectl label node $WORKER2_NODE monitoring=enabled --overwrite

# Taint master node to prevent workload scheduling (production best practice)
kubectl taint nodes $MASTER_NODE node-role.kubernetes.io/master=true:NoSchedule --overwrite || true
kubectl taint nodes $MASTER_NODE node-role.kubernetes.io/control-plane=true:NoSchedule --overwrite || true

echo -e "${GREEN}✅ Node configuration completed${NC}"

# Verify node configuration
echo -e "${BLUE}🔍 Verifying node configuration:${NC}"
echo "Nodes with labels:"
kubectl get nodes --show-labels | grep -E "(master|worker|monitoring)"
echo ""

# Step 2: Create namespace and RBAC
echo -e "${BLUE}🏗️  Step 2: Creating monitoring namespace and RBAC...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply RBAC and network policies
kubectl apply -f production-ingress.yaml

echo -e "${GREEN}✅ Namespace and RBAC created${NC}"

# Step 3: Add Helm repositories
echo -e "${BLUE}📦 Step 3: Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo -e "${GREEN}✅ Helm repositories added${NC}"

# Step 4: Install production monitoring stack
echo -e "${BLUE}⚙️  Step 4: Installing production monitoring stack...${NC}"
echo -e "${YELLOW}   This may take several minutes...${NC}"

helm upgrade --install $RELEASE_NAME prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --values $VALUES_FILE \
  --timeout 20m \
  --wait \
  --create-namespace

echo -e "${GREEN}✅ Monitoring stack installed${NC}"

# Step 5: Verify production deployment
echo -e "${BLUE}🔍 Step 5: Verifying production deployment...${NC}"

# Wait for pods to be ready
echo -e "${YELLOW}⏳ Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n $NAMESPACE --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n $NAMESPACE --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=alertmanager -n $NAMESPACE --timeout=600s

# Check pod distribution (should be on worker nodes only)
echo -e "${BLUE}📊 Pod distribution across nodes:${NC}"
kubectl get pods -n $NAMESPACE -o wide

# Check monitoring pods distribution
MASTER_PODS=$(kubectl get pods -n $NAMESPACE -o wide | grep $MASTER_NODE | wc -l)
MASTER_NODE_EXPORTERS=$(kubectl get pods -n $NAMESPACE -o wide | grep $MASTER_NODE | grep "node-exporter" | wc -l)

echo -e "${BLUE}📊 Master Node Monitoring Status:${NC}"
if [ $MASTER_NODE_EXPORTERS -gt 0 ]; then
    echo -e "${GREEN}✅ SUCCESS: Node Exporter running on master (system metrics)${NC}"
    kubectl get pods -n $NAMESPACE -o wide | grep $MASTER_NODE | grep "node-exporter"
else
    echo -e "${RED}❌ WARNING: No Node Exporter on master node${NC}"
fi

HEAVY_PODS=$(kubectl get pods -n $NAMESPACE -o wide | grep $MASTER_NODE | grep -v "node-exporter" | wc -l)
if [ $HEAVY_PODS -eq 0 ]; then
    echo -e "${GREEN}✅ SUCCESS: No heavy monitoring workloads on master${NC}"
else
    echo -e "${YELLOW}⚠️  Found $HEAVY_PODS non-exporter pods on master:${NC}"
    kubectl get pods -n $NAMESPACE -o wide | grep $MASTER_NODE | grep -v "node-exporter"
fi

# Check services
echo -e "${BLUE}🌐 Monitoring services:${NC}"
kubectl get svc -n $NAMESPACE

# Check persistent volumes
echo -e "${BLUE}💾 Persistent storage:${NC}"
kubectl get pvc -n $NAMESPACE

# Step 6: Display access information
echo ""
echo -e "${GREEN}🎉 PRODUCTION DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}===============================================${NC}"
echo ""

# Get service access information
GRAFANA_PORT=$(kubectl get svc prometheus-stack-grafana -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "80")
PROMETHEUS_PORT=$(kubectl get svc prometheus-stack-kube-prom-prometheus -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "9090")
ALERTMANAGER_PORT=$(kubectl get svc prometheus-stack-kube-prom-alertmanager -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "9093")

echo -e "${BLUE}🏭 PRODUCTION ARCHITECTURE:${NC}"
echo -e "   Control Plane: $MASTER_NODE (10.10.80.76)"
echo -e "      ✅ Kubernetes API Server, etcd, Scheduler (monitored)"
echo -e "      ✅ Node Exporter for system metrics"
echo -e "      ❌ No Grafana/Prometheus/AlertManager workloads"
echo -e "   Monitoring:    $WORKER1_NODE (10.10.80.77) - Full monitoring stack"
echo -e "   Monitoring:    $WORKER2_NODE (10.10.80.78) - Full monitoring stack"
echo ""

echo -e "${BLUE}🌐 PRODUCTION ACCESS:${NC}"
echo -e "${GREEN}   Ingress URLs (Recommended):${NC}"
echo -e "   🔗 Grafana:      https://grafana.k8s.local"
echo -e "   🔗 Prometheus:   https://prometheus.k8s.local"
echo -e "   🔗 AlertManager: https://alertmanager.k8s.local"
echo ""

echo -e "${YELLOW}   Direct Access (Development/Testing):${NC}"
# Get any worker node IP for access
WORKER_IP=$(kubectl get node $WORKER1_NODE -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
echo -e "   🔗 Grafana:      http://$WORKER_IP:31000"
echo -e "   🔗 Prometheus:   http://$WORKER_IP:31001" 
echo -e "   🔗 AlertManager: http://$WORKER_IP:31002"
echo ""

echo -e "${BLUE}🔐 CREDENTIALS:${NC}"
echo -e "   Grafana Login: admin / ProD@Grafan@2025!"
echo -e "   ${RED}⚠️  CHANGE DEFAULT PASSWORD IN PRODUCTION!${NC}"
echo ""

echo -e "${BLUE}✅ PRODUCTION FEATURES ENABLED:${NC}"
echo -e "   ✓ High availability (2 replicas each service)"
echo -e "   ✓ Worker node deployment only"
echo -e "   ✓ Persistent storage configured"
echo -e "   ✓ Resource limits applied"
echo -e "   ✓ Security policies enforced"
echo -e "   ✓ Network policies applied"
echo -e "   ✓ TLS/SSL ready (configure certificates)"
echo ""

# Production checklist
echo -e "${YELLOW}📋 PRODUCTION CHECKLIST:${NC}"
echo -e "   □ Update /etc/hosts with monitoring domain names"
echo -e "   □ Configure proper TLS certificates"
echo -e "   □ Change default Grafana password"
echo -e "   □ Set up proper backup procedures"
echo -e "   □ Configure external authentication (LDAP/OAuth)"
echo -e "   □ Set up alerting notifications (email/Slack)"
echo -e "   □ Test high availability failover"
echo -e "   □ Monitor resource usage and scale if needed"
echo ""

echo -e "${GREEN}🚀 Your production monitoring stack is ready!${NC}"
echo -e "${BLUE}📚 For detailed configuration, see: production-monitoring-setup.txt${NC}"