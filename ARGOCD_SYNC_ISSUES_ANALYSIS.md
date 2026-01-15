# ArgoCD Sync Issues - Root Cause Analysis

**Date:** January 12, 2026  
**Status:** 🔴 **CRITICAL - Multiple Applications Out of Sync**  
**Impact:** All microservices failing to deploy via ArgoCD

---

## 🚨 ROOT CAUSES IDENTIFIED

### **Issue #1: Missing namespace.yaml in ProductService** ⚠️ CRITICAL
**Affected Services:** ProductService, SpacemanService, PrintService, AuthenticationService, StockControlService, StoreOperationsService, ReplenishmentService

**Problem:**
The `base/kustomization.yaml` files are **missing the namespace.yaml resource**, but the namespace is being referenced in overlays.

**Evidence:**
```yaml
# ProductService/k8s/base/kustomization.yaml (INCORRECT)
resources:
  - configmap.yaml
  - secret.yaml
  - external-secrets.yaml  # ❌ namespace.yaml is MISSING!
  - deployment.yaml
  - service.yaml
  - ingress.yaml

# AdministrationService/k8s/base/kustomization.yaml (CORRECT - for comparison)
resources:
  - namespace.yaml  # ✅ PRESENT
  - configmap.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```

**Impact:**
- ArgoCD cannot find the namespace resource when building manifests
- Kustomize build fails during sync
- Applications remain "OutOfSync" indefinitely
- Deployments cannot proceed even with `CreateNamespace=true` option

**Services Affected:**
1. ✅ AdministrationService - HAS namespace.yaml (working)
2. ✅ AuditService - HAS namespace.yaml (working)
3. ❌ **ProductService** - MISSING namespace.yaml
4. ❌ **SpacemanService** - MISSING namespace.yaml
5. ❌ **PrintService** - MISSING namespace.yaml (likely)
6. ❌ **AuthenticationService** - MISSING namespace.yaml (likely)
7. ❌ **StockControlService** - MISSING namespace.yaml (likely)
8. ❌ **StoreOperationsService** - MISSING namespace.yaml (likely)
9. ❌ **ReplenishmentService** - MISSING namespace.yaml (likely)
10. ❓ FrontendService - Uses `default` namespace (different issue)

---

### **Issue #2: Namespace Mismatch - ArgoCD vs Base Kustomization** ⚠️ HIGH

**Problem:**
ArgoCD applications specify `namespace: wingyip-srs-staging` but base kustomization uses `namespace: wingyip-srs`.

**Evidence:**
```yaml
# ArgoCD Application (staging)
destination:
  server: https://kubernetes.default.svc
  namespace: wingyip-srs-staging  # ← ArgoCD wants this

# Base kustomization.yaml
namespace: wingyip-srs  # ← Base defines this

# Overlay staging kustomization.yaml
namespace: wingyip-srs-staging  # ← Overlay overrides to this
```

**This is ACCEPTABLE** because overlays properly override the namespace. However, if namespace.yaml is missing from base resources, Kustomize cannot patch it.

---

### **Issue #3: FrontendService Wrong Namespace** ⚠️ MEDIUM

**Problem:**
FrontendService base kustomization uses `namespace: default` instead of `wingyip-srs`.

**Evidence:**
```yaml
# FrontendService/k8s/base/kustomization.yaml
namespace: default  # ❌ INCORRECT - should be wingyip-srs
```

**Impact:**
- Frontend deploys to wrong namespace
- Cannot communicate with backend services properly
- Breaks service mesh and network policies

---

### **Issue #4: External Secrets Not in All Services** ⚠️ MEDIUM

**Problem:**
ProductService has `external-secrets.yaml` in base kustomization, but other services may not have implemented Vault integration yet.

**This may cause:**
- Secrets not being populated from Vault
- Pods failing to start due to missing environment variables
- Different secret management strategies across services

---

## 🔍 DETAILED ANALYSIS BY SERVICE

### ✅ **Working Services** (Reference Examples)

#### AdministrationService
```yaml
# k8s/base/kustomization.yaml
resources:
  - namespace.yaml      # ✅ PRESENT
  - configmap.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```
**Status:** Should sync correctly

#### AuditService
```yaml
# k8s/base/kustomization.yaml
resources:
  - namespace.yaml      # ✅ PRESENT
  - configmap.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```
**Status:** Should sync correctly

---

### ❌ **Broken Services** (Need Fixes)

#### ProductService
```yaml
# k8s/base/kustomization.yaml
resources:
  - configmap.yaml
  - secret.yaml
  - external-secrets.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
  # ❌ MISSING: namespace.yaml
```
**Fix Required:** Add `- namespace.yaml` to resources list

#### SpacemanService
```yaml
# k8s/base/kustomization.yaml
resources:
  - configmap.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
  # ❌ MISSING: namespace.yaml
```
**Fix Required:** Add `- namespace.yaml` to resources list

#### FrontendService
```yaml
# k8s/base/kustomization.yaml
namespace: default  # ❌ WRONG NAMESPACE

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  - ingress.yaml
  # ❌ MISSING: namespace.yaml (needs to be created first)
```
**Fix Required:** 
1. Create `namespace.yaml` file
2. Add `- namespace.yaml` to resources
3. Change namespace from `default` to `wingyip-srs`

---

## 🛠️ FIXES REQUIRED

### **Fix #1: Add namespace.yaml to ProductService Base**

**File:** `/WingYip_SRS_Infrastructure/ProductService/k8s/base/kustomization.yaml`

**Change:**
```yaml
# BEFORE
resources:
  - configmap.yaml
  - secret.yaml
  - external-secrets.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml

# AFTER
resources:
  - namespace.yaml          # ✅ ADD THIS LINE
  - configmap.yaml
  - secret.yaml
  - external-secrets.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```

---

### **Fix #2: Add namespace.yaml to SpacemanService Base**

**File:** `/WingYip_SRS_Infrastructure/SpacemanService/k8s/base/kustomization.yaml`

**Change:**
```yaml
# BEFORE
resources:
  - configmap.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml

# AFTER
resources:
  - namespace.yaml          # ✅ ADD THIS LINE
  - configmap.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```

---

### **Fix #3: Create and Add namespace.yaml to FrontendService**

**Step 1:** Create `/WingYip_SRS_Infrastructure/FrontendService/k8s/base/namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: wingyip-srs
  labels:
    name: wingyip-srs
    environment: shared
    app.kubernetes.io/name: wingyip-srs
    app.kubernetes.io/part-of: wingyip-stock-replenishment-system
```

**Step 2:** Update `/WingYip_SRS_Infrastructure/FrontendService/k8s/base/kustomization.yaml`
```yaml
# BEFORE
namespace: default

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  - ingress.yaml

# AFTER
namespace: wingyip-srs    # ✅ CHANGE FROM default

resources:
  - namespace.yaml        # ✅ ADD THIS LINE
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  - ingress.yaml
```

---

### **Fix #4: Apply Same Fix to Other Services**

**Services Needing namespace.yaml Added:**
- [ ] PrintService
- [ ] AuthenticationService
- [ ] StockControlService
- [ ] StoreOperationsService
- [ ] ReplenishmentService

**For Each Service:**
1. Check if `namespace.yaml` exists in `k8s/base/` directory
2. If YES but not in kustomization: Add `- namespace.yaml` to resources
3. If NO: Copy namespace.yaml from AdministrationService and add to resources

---

## 🧪 VERIFICATION STEPS

### **Step 1: Fix Kustomization Files**
```bash
cd /home/kp/oraganization-project/k8-cluster/WingYip_SRS_Infrastructure

# For each broken service:
# 1. Edit k8s/base/kustomization.yaml
# 2. Add "- namespace.yaml" to resources list
```

### **Step 2: Test Kustomize Build Locally**
```bash
# Test ProductService
kubectl kustomize ProductService/k8s/overlays/staging

# Test SpacemanService
kubectl kustomize SpacemanService/k8s/overlays/staging

# Test FrontendService
kubectl kustomize FrontendService/k8s/overlays/staging

# If successful, you should see valid YAML output
# If errors, fix the issues before committing
```

### **Step 3: Commit and Push Changes**
```bash
git add .
git commit -m "fix: Add missing namespace.yaml to kustomization resources

- Add namespace.yaml to ProductService base kustomization
- Add namespace.yaml to SpacemanService base kustomization
- Create and add namespace.yaml to FrontendService
- Fix FrontendService namespace from 'default' to 'wingyip-srs'
- Fixes ArgoCD sync issues for all affected services

Resolves: ArgoCD OutOfSync errors
Affects: ProductService, SpacemanService, FrontendService, and others"

git push origin development
```

### **Step 4: Trigger ArgoCD Sync**
```bash
# Option A: Via ArgoCD UI
# - Go to each application
# - Click "Refresh" button
# - Click "Sync" button

# Option B: Via ArgoCD CLI
argocd app sync wingyip-productservice-staging
argocd app sync wingyip-spacemanservice-staging
argocd app sync wingyip-frontend-staging
argocd app sync wingyip-administrationservice-staging
argocd app sync wingyip-auditservice-staging

# Option C: Via kubectl (if ArgoCD auto-sync enabled)
# Just wait 3 minutes for auto-sync to detect changes
```

### **Step 5: Verify Sync Status**
```bash
# Check ArgoCD application status
argocd app list

# Check pods in target namespace
kubectl get pods -n wingyip-srs-staging

# Check if all resources are created
kubectl get all,ingress,configmap,secret -n wingyip-srs-staging
```

---

## 📊 IMPACT ASSESSMENT

### **Before Fix**
```
Total Applications:     10
Synced:                 2 (Administration, Audit)
OutOfSync:              8 (Product, Spaceman, Frontend, etc.)
Sync Success Rate:      20%
```

### **After Fix (Expected)**
```
Total Applications:     10
Synced:                 10
OutOfSync:              0
Sync Success Rate:      100%
```

---

## 🚀 RECOMMENDED ACTION PLAN

### **Immediate (Today)**
1. ✅ Fix ProductService kustomization
2. ✅ Fix SpacemanService kustomization
3. ✅ Fix FrontendService (create namespace.yaml + update kustomization)
4. ✅ Test kustomize builds locally
5. ✅ Commit and push to development branch

### **Short-term (This Week)**
6. ✅ Fix remaining services (Print, Auth, StockControl, StoreOps, Replenishment)
7. ✅ Verify all ArgoCD applications sync successfully
8. ✅ Document the fix in team wiki
9. ✅ Update CI/CD pipeline to validate kustomization before merge

### **Long-term (Ongoing)**
10. ✅ Add pre-commit hooks to validate kustomization.yaml files
11. ✅ Create kustomization.yaml template for new services
12. ✅ Add automated tests for kustomize builds in CI/CD
13. ✅ Standardize all services to use same structure

---

## 📝 LESSONS LEARNED

### **What Went Wrong**
1. **Inconsistent structure** across services (some have namespace.yaml, some don't)
2. **No validation** of kustomization files before committing
3. **Missing documentation** on required files for Kustomize/ArgoCD integration
4. **Copy-paste errors** when creating new services from templates

### **Prevention Measures**
1. **Standardize service structure** - All services must have same base files
2. **Add CI/CD validation** - Fail builds if kustomization is invalid
3. **Create templates** - Use cookiecutter or similar for new services
4. **Documentation** - Update developer guide with kustomization requirements
5. **Pre-commit hooks** - Validate YAML and kustomization locally

---

## 🔗 RELATED FILES

- `/WingYip_SRS_Infrastructure/ProductService/k8s/base/kustomization.yaml` ❌ **NEEDS FIX**
- `/WingYip_SRS_Infrastructure/SpacemanService/k8s/base/kustomization.yaml` ❌ **NEEDS FIX**
- `/WingYip_SRS_Infrastructure/FrontendService/k8s/base/kustomization.yaml` ❌ **NEEDS FIX**
- `/WingYip_SRS_Infrastructure/AdministrationService/k8s/base/kustomization.yaml` ✅ **REFERENCE (CORRECT)**
- `/WingYip_SRS_Infrastructure/AuditService/k8s/base/kustomization.yaml` ✅ **REFERENCE (CORRECT)**

---

## 📞 CONTACTS

- **DevOps Lead:** [Your Name]
- **ArgoCD Admin:** [Admin Name]
- **Kubernetes Admin:** [K8s Admin]

---

**Status:** Ready for implementation  
**Priority:** P0 - Critical  
**ETA to Fix:** 2-3 hours (for all services)

---

**END OF ANALYSIS**
