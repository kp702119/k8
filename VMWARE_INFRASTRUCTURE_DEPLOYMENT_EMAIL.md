# VMware Infrastructure Deployment - Detailed Requirements

**Date:** January 12, 2026  
**Subject:** WingYip SRS - Kubernetes Cluster Infrastructure Requirements for VMware Deployment  
**Project:** WingYip Store Replenishment System (SRS)  
**Status:** Infrastructure Planning Phase

---

## 📧 EMAIL TEMPLATE

**TO:** IT Infrastructure Team / Management  
**CC:** DevOps Team, Project Manager  
**SUBJECT:** WingYip SRS Kubernetes Cluster - VMware Infrastructure Requirements & Windows Server 2022 Licensing

---

### Dear Infrastructure Team,

We are preparing to deploy the **WingYip Store Replenishment System (SRS)** on our VMware infrastructure. This system comprises 10 microservices, a React frontend, React Native handheld app backend, and multiple supporting services (Vault, RabbitMQ, Elasticsearch, SQL Server).

After analyzing our application workloads and deployment manifests, we have determined the infrastructure requirements for a **4-server VMware deployment** consisting of:
- **1 Kubernetes Master Node**
- **2 Kubernetes Worker Nodes**
- **1 Dedicated Database Server**

Below are the detailed specifications, resource calculations, and Windows Server 2022 licensing requirements.

---

## 🖥️ SERVER SPECIFICATIONS

### **Server 1: Kubernetes Master Node**
**Purpose:** Control plane for Kubernetes cluster, etcd, scheduler, API server

| Component | Specification | Justification |
|-----------|--------------|---------------|
| **OS** | Windows Server 2022 Standard | Kubernetes control plane + Windows containers support |
| **vCPU** | **8 cores** | Control plane operations, etcd, API server, scheduler |
| **RAM** | **16 GB** | etcd (2-8GB), API server (4GB), controller-manager (2GB), scheduler (1GB), system overhead (4GB) |
| **Storage** | **200 GB SSD** | OS (60GB), etcd data (50GB), logs (30GB), container images (60GB) |
| **Network** | **2 NICs** | Management (1 NIC), Cluster communication (1 NIC) |
| **IP Address** | Static IP (10.10.80.70 suggested) | Master node requires stable IP |

**Windows Server License Required:** ✅ **1 x Windows Server 2022 Standard License**

---

### **Server 2: Kubernetes Worker Node 1**
**Purpose:** Run application pods (microservices, frontend, supporting services)

| Component | Specification | Justification |
|-----------|--------------|---------------|
| **OS** | Windows Server 2022 Standard | Container runtime for .NET microservices |
| **vCPU** | **16 cores** | 10 microservices + frontend + Vault + RabbitMQ + Elasticsearch |
| **RAM** | **32 GB** | Application pods (20GB), supporting services (8GB), system (4GB) |
| **Storage** | **300 GB SSD** | OS (60GB), container images (120GB), logs (50GB), persistent volumes (70GB) |
| **Network** | **2 NICs** | Management (1 NIC), Cluster/LoadBalancer (1 NIC) |
| **IP Address** | Static IP (10.10.80.77 - **currently in use**) | Worker node with MetalLB LoadBalancer |

**Windows Server License Required:** ✅ **1 x Windows Server 2022 Standard License**

**Current Resource Allocation (per deployment manifests):**
```
Microservices (10 services × 2 replicas avg):
  - CPU Requests: 250m × 20 = 5 cores
  - CPU Limits: 500m × 20 = 10 cores
  - Memory Requests: 256Mi × 20 = 5.12 GB
  - Memory Limits: 512Mi × 20 = 10.24 GB

Frontend (2 replicas):
  - CPU Requests: 100m × 2 = 0.2 cores
  - CPU Limits: 200m × 2 = 0.4 cores
  - Memory Requests: 128Mi × 2 = 256 MB
  - Memory Limits: 256Mi × 2 = 512 MB

Supporting Services:
  - Vault: 1 core, 2 GB
  - RabbitMQ: 2 cores, 4 GB
  - Elasticsearch: 2 cores, 4 GB

Total Worker Node 1:
  - CPU: ~15 cores needed
  - Memory: ~20 GB needed
```

---

### **Server 3: Kubernetes Worker Node 2**
**Purpose:** High availability, load distribution, redundancy

| Component | Specification | Justification |
|-----------|--------------|---------------|
| **OS** | Windows Server 2022 Standard | Container runtime for .NET microservices |
| **vCPU** | **16 cores** | Mirror of Worker Node 1 for HA and load balancing |
| **RAM** | **32 GB** | Mirror of Worker Node 1 for redundancy |
| **Storage** | **300 GB SSD** | OS (60GB), container images (120GB), logs (50GB), persistent volumes (70GB) |
| **Network** | **2 NICs** | Management (1 NIC), Cluster/LoadBalancer (1 NIC) |
| **IP Address** | Static IP (10.10.80.78 suggested) | Worker node for HA |

**Windows Server License Required:** ✅ **1 x Windows Server 2022 Standard License**

**Purpose:**
- Load balance with Worker Node 1
- Ensure high availability (if Worker Node 1 fails)
- Allow zero-downtime rolling updates
- Distribute pod replicas across nodes

---

### **Server 4: Database Server (SQL Server)**
**Purpose:** Dedicated SQL Server 2022 for all microservice databases

| Component | Specification | Justification |
|-----------|--------------|---------------|
| **OS** | Windows Server 2022 Standard | SQL Server 2022 Enterprise/Standard host |
| **vCPU** | **12 cores** | Database operations for 10 microservices |
| **RAM** | **64 GB** | SQL Server memory (48GB), OS (4GB), buffer pool (12GB) |
| **Storage (OS)** | **120 GB SSD** | Operating system and SQL Server installation |
| **Storage (Data)** | **500 GB SSD** | Database files (MDF/NDF) for 10 databases |
| **Storage (Logs)** | **200 GB SSD** | Transaction logs (LDF files) |
| **Storage (Backup)** | **1 TB HDD** | Database backups and archives |
| **Network** | **2 NICs** | Management (1 NIC), Database traffic (1 NIC) |
| **IP Address** | Static IP (10.10.80.81 - **currently configured**) | Database server endpoint |

**Windows Server License Required:** ✅ **1 x Windows Server 2022 Standard License**  
**SQL Server License Required:** ✅ **1 x SQL Server 2022 Standard/Enterprise License** (12 cores)

**Current Databases (from vault script):**
1. WingYip_SRS_Administration_Database_stage
2. WingYip_SRS_Audit_Database_stage
3. WingYip_SRS_Authentication_Database_stage
4. WingYip_SRS_Product_Database_stage
5. WingYip_SRS_Spaceman_Database_stage
6. WingYip_SRS_StockControl_Database_stage
7. WingYip_SRS_Print_Database_stage (planned)
8. WingYip_SRS_Replenishment_Database_stage (planned)
9. WingYip_SRS_StoreOperations_Database_stage (planned)
10. WingYip_SRS_Handheld_Database_stage (planned)

**SQL Server Resource Allocation:**
- **Memory:** 48GB for SQL Server (recommended: 75% of total RAM)
- **CPU:** 12 cores for parallel query execution
- **IOPS:** 10,000+ IOPS required (SSD mandatory)
- **Estimated Database Size:** 200 GB (data) + 50 GB (logs) + 500 GB (backups)

---

## 📊 TOTAL INFRASTRUCTURE SUMMARY

| Server | Role | vCPU | RAM | Storage | Windows License |
|--------|------|------|-----|---------|-----------------|
| **Server 1** | K8s Master | 8 cores | 16 GB | 200 GB SSD | ✅ WS2022 Standard |
| **Server 2** | K8s Worker 1 | 16 cores | 32 GB | 300 GB SSD | ✅ WS2022 Standard |
| **Server 3** | K8s Worker 2 | 16 cores | 32 GB | 300 GB SSD | ✅ WS2022 Standard |
| **Server 4** | SQL Server | 12 cores | 64 GB | 120GB SSD + 500GB SSD + 200GB SSD + 1TB HDD | ✅ WS2022 Standard |
| **TOTAL** | - | **52 cores** | **144 GB** | **2.52 TB** | **4 Licenses** |

---

## 🪟 WINDOWS SERVER 2022 LICENSING REQUIREMENTS

### **License Summary**
- **Required Licenses:** 4 × Windows Server 2022 Standard Edition
- **Licensing Model:** Per-core licensing (minimum 16 cores per license)
- **Total Cores Covered:** 52 physical cores

### **License Breakdown by Server**
1. **Master Node (8 cores):** 1 × WS2022 Standard (16-core minimum) ✅
2. **Worker Node 1 (16 cores):** 1 × WS2022 Standard (16-core license) ✅
3. **Worker Node 2 (16 cores):** 1 × WS2022 Standard (16-core license) ✅
4. **DB Server (12 cores):** 1 × WS2022 Standard (16-core minimum) ✅

### **Additional SQL Server Licensing**
- **SQL Server 2022 Standard Edition:** 1 × 12-core license
  - **OR** SQL Server 2022 Enterprise Edition (if advanced features needed)
- **Licensing Model:** Per-core (minimum 4 cores per license)

### **Estimated Licensing Costs (MSFT Retail Pricing)**
| License | Quantity | Unit Price (USD) | Total (USD) |
|---------|----------|------------------|-------------|
| Windows Server 2022 Standard (16-core) | 4 | $1,069 | **$4,276** |
| SQL Server 2022 Standard (2-core pack) | 6 | $3,717 | **$22,302** |
| **GRAND TOTAL** | - | - | **$26,578** |

**Note:** Volume licensing (e.g., Microsoft Enterprise Agreement) may reduce costs significantly. Please consult with Microsoft licensing specialist or reseller.

---

## 🌐 NETWORK REQUIREMENTS

### **IP Address Allocation**
| Server | IP Address | Subnet | Gateway | DNS |
|--------|------------|--------|---------|-----|
| K8s Master | 10.10.80.70 | 255.255.255.0 | 10.10.80.1 | 10.10.80.1 |
| K8s Worker 1 | 10.10.80.77 (existing) | 255.255.255.0 | 10.10.80.1 | 10.10.80.1 |
| K8s Worker 2 | 10.10.80.78 | 255.255.255.0 | 10.10.80.1 | 10.10.80.1 |
| SQL Server | 10.10.80.81 (existing) | 255.255.255.0 | 10.10.80.1 | 10.10.80.1 |

### **Firewall Rules Required**

#### **Kubernetes Cluster Communication**
| Protocol | Port | Source | Destination | Purpose |
|----------|------|--------|-------------|---------|
| TCP | 6443 | Worker Nodes | Master Node | Kubernetes API Server |
| TCP | 2379-2380 | Master Node | Master Node | etcd client/peer |
| TCP | 10250 | Master, Workers | All Nodes | Kubelet API |
| TCP | 10251 | Master | Master | kube-scheduler |
| TCP | 10252 | Master | Master | kube-controller-manager |
| TCP | 10255 | All | All Nodes | Read-only Kubelet API |
| TCP | 30000-32767 | Clients | Worker Nodes | NodePort Services |

#### **Application Services**
| Service | Port | Source | Destination | Purpose |
|---------|------|--------|-------------|---------|
| SQL Server | 1433 | Worker Nodes | DB Server (10.10.80.81) | Database connections |
| RabbitMQ | 5672 | Worker Nodes | Worker Nodes | Message queue |
| RabbitMQ Management | 15672 | Admins | Worker Nodes | RabbitMQ UI |
| Elasticsearch | 9200, 9300 | Worker Nodes | Worker Nodes | Search indexing |
| Vault | 8200 | Worker Nodes | Worker Nodes | Secret management |
| Harbor (Docker Registry) | 30280 | Worker Nodes | Worker Nodes | Container images |
| Frontend | 80, 443 | Users | Worker Nodes | Web application |

#### **Management Access**
| Protocol | Port | Source | Destination | Purpose |
|----------|------|--------|-------------|---------|
| RDP | 3389 | Admin IPs | All Servers | Remote administration |
| WinRM | 5985, 5986 | Admin IPs | All Servers | PowerShell remoting |
| SSH (optional) | 22 | Admin IPs | All Servers | SSH access |

### **DNS Requirements**
- **Internal DNS Records:**
  - `k8s-master.wingyip.local` → 10.10.80.70
  - `k8s-worker1.wingyip.local` → 10.10.80.77
  - `k8s-worker2.wingyip.local` → 10.10.80.78
  - `sqlserver.wingyip.local` → 10.10.80.81

### **Load Balancer (MetalLB)**
- **IP Pool:** 10.10.80.77 (currently configured)
- **Mode:** Layer 2 (L2Advertisement)
- **Services Exposed:**
  - Frontend: Port 80 (HTTP), 443 (HTTPS)
  - API Gateway: Port 8080
  - Microservices: NodePort range 30000-32767

---

## 🗂️ STORAGE REQUIREMENTS

### **Storage Type by Server**
| Server | Storage Type | Size | Purpose | IOPS Requirement |
|--------|--------------|------|---------|------------------|
| Master Node | SSD | 200 GB | OS, etcd, logs | 3,000 IOPS |
| Worker Node 1 | SSD | 300 GB | OS, containers, logs | 5,000 IOPS |
| Worker Node 2 | SSD | 300 GB | OS, containers, logs | 5,000 IOPS |
| DB Server (OS) | SSD | 120 GB | Windows Server 2022 | 2,000 IOPS |
| DB Server (Data) | SSD | 500 GB | SQL data files (MDF/NDF) | 10,000 IOPS |
| DB Server (Logs) | SSD | 200 GB | SQL log files (LDF) | 8,000 IOPS |
| DB Server (Backup) | HDD | 1 TB | Backup storage | 500 IOPS |
| **TOTAL** | - | **2.52 TB** | - | - |

### **Backup Strategy**
- **Database Backups:** Daily full, hourly transaction log backups
- **Kubernetes etcd Backups:** Daily snapshots
- **Container Image Registry Backups:** Weekly
- **Retention:** 30 days (daily), 90 days (weekly), 1 year (monthly)

---

## 🔧 VMWARE CONFIGURATION RECOMMENDATIONS

### **Resource Allocation**
- **CPU Overcommitment Ratio:** 1:1 (no overcommitment for production)
- **Memory Overcommitment:** Not recommended (100% reservation)
- **Disk Provisioning:** Thick provisioning (eager zeroed) for SQL Server
- **Network Adapter:** VMXNET3 (for best performance)

### **High Availability**
- **vSphere HA:** Enabled (automatic VM restart on host failure)
- **DRS (Distributed Resource Scheduler):** Enabled (load balancing)
- **Anti-Affinity Rules:** 
  - Keep Worker Node 1 and Worker Node 2 on different ESXi hosts
  - Keep Master Node and DB Server on different ESXi hosts

### **Snapshots & Backups**
- **VM Snapshots:** Not recommended for SQL Server (use SQL backup instead)
- **Veeam/Backup Solution:** Configure for all 4 VMs
- **Snapshot Frequency:** Master Node (daily), Worker Nodes (weekly), DB Server (via SQL tools)

### **Performance Monitoring**
- **vCenter Monitoring:** Enable CPU, memory, disk, network monitoring
- **Alerts:** Set up alerts for:
  - CPU usage > 80%
  - Memory usage > 90%
  - Disk latency > 20ms
  - Network packet loss > 1%

---

## 📅 DEPLOYMENT TIMELINE

### **Phase 1: Infrastructure Provisioning (Week 1)**
- [ ] Procure Windows Server 2022 licenses (4 licenses)
- [ ] Procure SQL Server 2022 license (1 license)
- [ ] Create 4 VMs in VMware with specifications above
- [ ] Install Windows Server 2022 on all 4 servers
- [ ] Configure static IP addresses
- [ ] Configure firewall rules
- [ ] Join servers to Active Directory (if applicable)

### **Phase 2: Kubernetes Installation (Week 2)**
- [ ] Install Docker/containerd on all Kubernetes nodes
- [ ] Initialize Kubernetes master node
- [ ] Join worker nodes to cluster
- [ ] Install MetalLB for load balancing
- [ ] Install External Secrets Operator
- [ ] Install Helm, kubectl tools

### **Phase 3: SQL Server Setup (Week 2)**
- [ ] Install SQL Server 2022 on DB server
- [ ] Configure SQL Server for remote connections
- [ ] Create 10 microservice databases
- [ ] Configure SQL authentication (sa account)
- [ ] Set up SQL Server backup jobs
- [ ] Configure firewall for port 1433

### **Phase 4: Supporting Services (Week 3)**
- [ ] Deploy HashiCorp Vault on worker nodes
- [ ] Deploy RabbitMQ on worker nodes
- [ ] Deploy Elasticsearch on worker nodes
- [ ] Deploy Harbor (container registry)
- [ ] Configure Vault secrets (via `store-staging-secrets-in-vault.sh`)
- [ ] Test connectivity between services

### **Phase 5: Application Deployment (Week 4)**
- [ ] Build and push Docker images to Harbor
- [ ] Deploy 10 microservices to Kubernetes
- [ ] Deploy React frontend to Kubernetes
- [ ] Configure External Secrets Operator
- [ ] Run smoke tests and integration tests
- [ ] Load testing and performance tuning

### **Phase 6: Go-Live Preparation (Week 5)**
- [ ] User acceptance testing (UAT)
- [ ] Security hardening and penetration testing
- [ ] Disaster recovery drills
- [ ] Document operational procedures
- [ ] Train operations team
- [ ] Go-live approval

---

## 🛡️ SECURITY CONSIDERATIONS

### **Windows Server Hardening**
- [ ] Enable Windows Firewall on all servers
- [ ] Disable unnecessary services (e.g., Telnet, FTP)
- [ ] Configure Windows Update (automated patching)
- [ ] Enable BitLocker encryption on all disks
- [ ] Configure audit logging (Windows Event Log)
- [ ] Install antivirus/endpoint protection

### **SQL Server Security**
- [ ] Disable SQL Server Browser service
- [ ] Use strong SA password (stored in Vault)
- [ ] Enable Transparent Data Encryption (TDE)
- [ ] Configure SQL Server Audit
- [ ] Restrict SQL Server port (1433) to worker nodes only
- [ ] Use Windows Authentication where possible

### **Kubernetes Security**
- [ ] Enable Role-Based Access Control (RBAC)
- [ ] Use Network Policies to restrict pod-to-pod traffic
- [ ] Scan container images for vulnerabilities
- [ ] Store all secrets in HashiCorp Vault (not K8s secrets)
- [ ] Enable Pod Security Policies
- [ ] Regularly update Kubernetes to latest stable version

---

## 💰 COST SUMMARY

### **Hardware/VMware Resources**
| Resource | Quantity | Unit Cost (estimated) | Total (USD) |
|----------|----------|----------------------|-------------|
| vCPU (52 cores) | 52 | Included in VMware license | - |
| RAM (144 GB) | 144 GB | Included in VMware license | - |
| SSD Storage (1.52 TB) | 1.52 TB | $0.20/GB/month | **$304/month** |
| HDD Storage (1 TB) | 1 TB | $0.05/GB/month | **$50/month** |
| **Total Infrastructure** | - | - | **$354/month** |

### **Software Licensing (One-time)**
| License | Quantity | Total (USD) |
|---------|----------|-------------|
| Windows Server 2022 Standard | 4 | **$4,276** |
| SQL Server 2022 Standard | 1 (12-core) | **$22,302** |
| **Total Licensing** | - | **$26,578** |

### **Annual Maintenance & Support**
| Service | Cost (USD/year) |
|---------|-----------------|
| Microsoft Software Assurance | **$2,000** |
| VMware Support | **$1,500** |
| Monitoring Tools | **$1,000** |
| Backup Solution | **$2,500** |
| **Total Annual** | **$7,000** |

### **Grand Total (Year 1)**
```
One-time Licensing: $26,578
Infrastructure (12 months): $4,248
Annual Support: $7,000
──────────────────────────
TOTAL YEAR 1: $37,826
```

---

## 📞 NEXT STEPS & ACTION ITEMS

### **Immediate Actions Required**
1. **[ ] Approve infrastructure budget ($37,826 for Year 1)**
2. **[ ] Procure Windows Server 2022 licenses (4 licenses) - Contact Microsoft reseller**
3. **[ ] Procure SQL Server 2022 license (12-core) - Contact Microsoft reseller**
4. **[ ] Allocate VMware resources (52 vCPU, 144 GB RAM, 2.52 TB storage)**
5. **[ ] Assign static IP addresses (10.10.80.70, .78 - .77 and .81 already in use)**
6. **[ ] Configure firewall rules (see Network Requirements section)**
7. **[ ] Schedule infrastructure provisioning (target: Week 1)**

### **Contacts for Licensing**
- **Microsoft Volume Licensing:** Contact your Microsoft account manager or visit [https://www.microsoft.com/licensing](https://www.microsoft.com/licensing)
- **Authorized Resellers:** CDW, SHI, Insight, Softchoice, etc.
- **Microsoft Open License:** For organizations under 250 users
- **Enterprise Agreement:** For organizations with 500+ users (best pricing)

### **Technical Contacts**
- **DevOps Lead:** [Your Name] - [Your Email]
- **Infrastructure Team:** [IT Manager Name] - [Email]
- **Database Administrator:** [DBA Name] - [Email]
- **VMware Administrator:** [VMware Admin Name] - [Email]

---

## 📎 ATTACHMENTS

1. **Kubernetes Deployment Manifests:** `/WingYip_SRS_Infrastructure/`
2. **Vault Configuration Script:** `store-staging-secrets-in-vault.sh`
3. **Network Diagram:** See ARCHITECTURE_DIAGRAM.md
4. **Resource Calculation Spreadsheet:** (To be created)
5. **Windows Server 2022 Datasheet:** [Link to Microsoft docs]
6. **SQL Server 2022 Datasheet:** [Link to Microsoft docs]

---

## ❓ FREQUENTLY ASKED QUESTIONS

### **Q: Why do we need 4 servers instead of 3?**
**A:** 
- 1 Master Node is required for Kubernetes control plane (cannot run application pods)
- 2 Worker Nodes ensure high availability and load distribution
- 1 Dedicated DB Server isolates database workload for performance and security

### **Q: Can we use Linux instead of Windows Server?**
**A:** 
- **Yes, for Kubernetes nodes** - Linux (Ubuntu/RHEL) would reduce licensing costs
- **No, for SQL Server** - We need Windows + SQL Server Standard/Enterprise
- **Recommendation:** Consider Linux for K8s nodes, Windows for DB server only

**Cost Savings with Linux K8s:**
- **Linux K8s nodes (3 servers):** Free OS (Ubuntu Server)
- **Windows DB Server (1 server):** $1,069 (Windows) + $22,302 (SQL Server)
- **Total Savings:** ~$3,200 in Windows licensing

### **Q: Do we need SQL Server Enterprise or Standard?**
**A:**
- **SQL Server Standard** is sufficient for current workload
- **Consider Enterprise if you need:**
  - Database mirroring (high availability)
  - Always On Availability Groups
  - Online index rebuilds
  - Columnstore indexes (for analytics)

### **Q: Can we run SQL Server in a Kubernetes container?**
**A:**
- **Yes, but not recommended for production** due to:
  - Performance overhead
  - Complexity in backup/restore
  - Licensing complications
- **Recommendation:** Dedicated VM for SQL Server

### **Q: What if we don't have Windows Server licenses yet?**
**A:**
- **Option 1:** Windows Server 2022 Evaluation Edition (180-day trial)
- **Option 2:** Use Linux for K8s nodes, defer DB server deployment
- **Option 3:** Rent licenses via Cloud Service Provider (Azure, AWS)

---

## ✅ APPROVAL SIGN-OFF

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **IT Manager** | | | |
| **Finance Manager** | | | |
| **DevOps Lead** | | | |
| **Project Manager** | | | |
| **CTO/CIO** | | | |

---

**Prepared by:** DevOps Team  
**Date:** January 12, 2026  
**Version:** 1.0  
**Status:** Awaiting Approval

---

## 📚 REFERENCES

- [Microsoft Windows Server 2022 Licensing Guide](https://www.microsoft.com/en-us/licensing/product-licensing/windows-server)
- [Microsoft SQL Server 2022 Licensing Guide](https://www.microsoft.com/en-us/licensing/product-licensing/sql-server)
- [Kubernetes Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)
- [VMware vSphere Performance Best Practices](https://www.vmware.com/resources/compatibility/search.php)

---

**END OF DOCUMENT**
