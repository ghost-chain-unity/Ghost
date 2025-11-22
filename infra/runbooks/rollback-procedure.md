# Application Deployment Rollback Procedure

## Overview

This runbook provides comprehensive procedures for rolling back failed or problematic deployments across all Ghost Protocol components.

**Severity:** High  
**Estimated Time:** 5-45 minutes (depending on rollback scope)  
**Last Updated:** 2025-11-16

## When to Rollback

### Immediate Rollback Required (< 5 minutes decision time)

- **Error rate >10%** after deployment
- **Complete service outage** (all pods CrashLoopBackOff)
- **Critical security vulnerability** introduced
- **Data corruption or data loss** detected
- **Failed health checks** on >50% of pods
- **User reports of critical bugs** within minutes of deployment

### Rollback Considered (< 15 minutes decision time)

- **Performance degradation >2x** normal latency
- **Error rate 5-10%** sustained for >5 minutes
- **Non-critical features broken** but service functional
- **Database migration issues** (schema conflicts)
- **Failed canary deployment** (error rate on canary pods)

### Do NOT Rollback

- **Minor UI bugs** (non-blocking, cosmetic)
- **Error rate <5%** and decreasing
- **Isolated incidents** affecting <10 users
- **Expected behavior** during feature flag rollout
- **Already applied database migrations** (rollback migrations instead)

## Decision Tree: What to Rollback?

```
Deployment Failed?
    │
    ├─ Backend Services (API, Indexer, RPC)
    │   ├─ Recent Kubernetes deployment?
    │   │   └─ Method 1: Kubernetes Rollback ⏱️ 2-5 min
    │   └─ Code changes only (no K8s changes)?
    │       └─ Method 1: Kubernetes Rollback ⏱️ 2-5 min
    │
    ├─ Frontend (Web, Admin Dashboard)
    │   ├─ Recent deployment to S3/CloudFront?
    │   │   └─ Method 4: Frontend Rollback ⏱️ 5-10 min
    │   └─ CDN cache issue?
    │       └─ Invalidate CloudFront cache only
    │
    ├─ Infrastructure (Terraform)
    │   └─ Method 2: Terraform Rollback ⏱️ 10-30 min
    │
    ├─ Database (Migrations)
    │   └─ Method 3: Database Migration Rollback ⏱️ 5-20 min
    │
    └─ Smart Contracts (Blockchain)
        ├─ Contract deployed to mainnet?
        │   └─ Method 5: Smart Contract Emergency Actions ⏱️ 10-45 min
        └─ Contract on testnet?
            └─ Redeploy previous version
```

## Prerequisites

### Required Access
- kubectl access to EKS cluster (admin permissions)
- AWS Console access (S3, CloudFront, Terraform)
- Database admin credentials
- GitHub/GitLab access (deployment history)
- Blockchain wallet access (for smart contracts)

### Required Tools
```bash
kubectl version        # kubectl 1.28+
aws --version          # AWS CLI v2.x
terraform --version    # Terraform 1.5+
psql --version         # PostgreSQL client 14+
node --version         # Node.js 20+ (for Prisma)
git --version          # Git 2.x
```

### Environment Setup
```bash
export AWS_REGION="us-east-1"
export ENVIRONMENT="prod"  # or dev/staging
export CLUSTER_NAME="ghost-protocol-${ENVIRONMENT}"
export NAMESPACE="ghost-protocol-${ENVIRONMENT}"

# Configure kubectl
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
```

## Method 1: Kubernetes Rollback (Backend Services)

**Use for:** API Gateway, Indexer, RPC Orchestrator, AI Engine

**Estimated Time:** 2-5 minutes  
**Impact:** Brief service disruption during pod restart

### Step 1.1: Identify Problematic Deployment

```bash
# Check recent deployments
kubectl rollout history deployment/api-gateway -n $NAMESPACE

# Expected output:
# REVISION  CHANGE-CAUSE
# 42        Image: api-gateway:v2.5.2
# 43        Image: api-gateway:v2.5.3 (current - PROBLEMATIC)
```

### Step 1.2: Verify Current State

```bash
# Check pod status
kubectl get pods -n $NAMESPACE -l app=api-gateway

# Check error logs
kubectl logs -n $NAMESPACE -l app=api-gateway --tail=50 | grep -i error

# Check error rate
# → Review Grafana dashboard: https://grafana.ghost-protocol.io/d/api-overview
```

**Decision Point:** If error rate is >20% and increasing, proceed immediately with rollback.

### Step 1.3: Perform Rollback

```bash
# Option A: Rollback to previous revision (RECOMMENDED)
kubectl rollout undo deployment/api-gateway -n $NAMESPACE

# Option B: Rollback to specific revision
kubectl rollout undo deployment/api-gateway --to-revision=42 -n $NAMESPACE

# Monitor rollback progress
kubectl rollout status deployment/api-gateway -n $NAMESPACE

# Expected:
# Waiting for deployment "api-gateway" rollout to finish: 1 old replicas are pending termination...
# deployment "api-gateway" successfully rolled out
```

**What happens during rollback:**
1. Kubernetes creates new pods with previous image version
2. Old pods (problematic version) are terminated gracefully
3. Rolling update ensures zero-downtime (some pods always available)
4. Rollback completes when all pods are running new (old) version

### Step 1.4: Verify Rollback Success

```bash
# Check pod status (all should be Running)
kubectl get pods -n $NAMESPACE -l app=api-gateway

# Check pod logs (should not show errors)
kubectl logs -n $NAMESPACE -l app=api-gateway --tail=50

# Test API health endpoint
curl -f https://api.ghost-protocol.io/health

# Expected: {"status":"ok","version":"v2.5.2"}

# Check error rate in Grafana (should return to <1%)
# https://grafana.ghost-protocol.io/d/api-overview
```

**Verification Checklist:**
- [ ] All pods are Running and Ready (3/3, 2/2, etc.)
- [ ] No errors in pod logs (last 5 minutes)
- [ ] API health check returns 200 OK
- [ ] Error rate <1% (within normal range)
- [ ] Response time within SLA (p95 <500ms)
- [ ] User reports confirm service restored

### Step 1.5: Multiple Services Rollback

If multiple services were deployed together and all need rollback:

```bash
# Rollback all services in parallel
for service in api-gateway indexer rpc-orchestrator ai-engine; do
  echo "Rolling back $service..."
  kubectl rollout undo deployment/$service -n $NAMESPACE &
done

# Wait for all rollbacks to complete
wait

# Verify all services
kubectl get pods -n $NAMESPACE
```

## Method 2: Terraform Infrastructure Rollback

**Use for:** EKS changes, RDS changes, networking, IAM roles

**Estimated Time:** 10-30 minutes  
**Impact:** Depends on resource type (some may cause downtime)

**⚠️ WARNING:** Infrastructure rollback can be destructive. Proceed with extreme caution.

### Step 2.1: Identify Problematic Terraform Change

```bash
cd infra/terraform

# Check recent Terraform changes
git log --oneline --since="2 hours ago"

# Example output:
# abc123 Update EKS node group instance type
# def456 Modify RDS instance class
```

### Step 2.2: Review Terraform State

```bash
# See what Terraform would change if we revert the commit
git diff HEAD~1 HEAD

# Check current Terraform state
terraform show

# Identify the specific resources that need rollback
terraform state list | grep -E "(eks|rds|vpc)"
```

### Step 2.3: Decide Rollback Strategy

**Option A: Git Revert (RECOMMENDED for most cases)**
```bash
# Revert the problematic commit
git revert abc123

# Review the revert changes
git diff HEAD~1 HEAD

# This creates a new commit that undoes the changes
# History is preserved (good for audit trail)
```

**Option B: Git Reset (DANGEROUS - only for unreleased changes)**
```bash
# ⚠️ WARNING: This rewrites history!
# Only use if changes haven't been pushed to main branch

git reset --hard HEAD~1

# This permanently removes the commit from history
```

### Step 2.4: Plan Terraform Rollback

```bash
# Generate Terraform plan with reverted changes
terraform plan -var-file=environments/${ENVIRONMENT}/terraform.tfvars -out=rollback.tfplan

# CAREFULLY review the plan
# Look for:
# - Resources being destroyed (❌ usually bad)
# - Resources being modified in-place (⚠️ check for downtime)
# - Resources being created (✅ usually safe)
```

**Critical Questions:**
- Will this cause downtime? (check for resource replacement)
- Will data be lost? (check for database/storage deletions)
- Are dependent services affected? (check for security group, IAM changes)

### Step 2.5: Execute Terraform Rollback

```bash
# If plan looks safe, apply the rollback
terraform apply rollback.tfplan

# Monitor Terraform output carefully
# Watch for errors or unexpected resource changes

# Expected duration:
# - IAM/Security Group changes: 1-2 minutes
# - EKS node group changes: 10-15 minutes
# - RDS instance class changes: 15-30 minutes (with downtime!)
```

### Step 2.6: Verify Infrastructure Rollback

```bash
# Verify EKS cluster is healthy
kubectl get nodes
kubectl get pods -A

# Verify RDS database is accessible
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres -c "SELECT version();"

# Check CloudWatch for any new alarms
aws cloudwatch describe-alarms --state-value ALARM --region $AWS_REGION

# Test application functionality
curl -f https://api.ghost-protocol.io/health
```

## Method 3: Database Migration Rollback

**Use for:** Prisma migrations, schema changes, data migrations

**Estimated Time:** 5-20 minutes (depends on migration complexity)  
**Impact:** May require brief application downtime

**⚠️ WARNING:** Database rollbacks can be complex and risky. Some migrations are irreversible.

### Step 3.1: Identify Problematic Migration

```bash
# Connect to database
export DATABASE_URL="postgresql://user:pass@endpoint:5432/db"

# Check migration history
npx prisma migrate status

# Expected output:
# 20251115_120000_add_user_table      ✅ Applied
# 20251116_140000_add_email_index     ✅ Applied (PROBLEMATIC)
```

### Step 3.2: Assess Rollback Feasibility

**Types of Migrations:**

| Migration Type | Rollback Difficulty | Risk |
|----------------|---------------------|------|
| Add column (nullable) | Easy | Low |
| Add column (NOT NULL) | Medium | Medium (requires default value) |
| Drop column | Hard | High (data loss!) |
| Rename column | Medium | Medium (requires coordinated app rollback) |
| Add index | Easy | Low |
| Drop index | Easy | Low |
| Add table | Easy | Low |
| Drop table | Hard | Critical (permanent data loss!) |
| Data migration | Hard | High (depends on complexity) |

**Decision:**
- **Easy (Low Risk):** Proceed with rollback
- **Medium:** Create backup snapshot first, then rollback
- **Hard/Critical:** Consider forward fix instead of rollback

### Step 3.3: Backup Database Before Rollback

```bash
# Create manual snapshot (CRITICAL step!)
aws rds create-db-snapshot \
  --db-instance-identifier ghost-protocol-${ENVIRONMENT}-db \
  --db-snapshot-identifier pre-migration-rollback-$(date +%Y%m%d-%H%M%S) \
  --region $AWS_REGION

# Wait for snapshot to complete (5-15 minutes)
aws rds wait db-snapshot-completed \
  --db-snapshot-identifier pre-migration-rollback-$(date +%Y%m%d-%H%M%S) \
  --region $AWS_REGION
```

### Step 3.4: Stop Application Writes

```bash
# Scale down write-capable services
kubectl scale deployment api-gateway --replicas=0 -n $NAMESPACE
kubectl scale deployment indexer --replicas=0 -n $NAMESPACE

# Verify no pods are running
kubectl get pods -n $NAMESPACE | grep -E "(api-gateway|indexer)"
# Expected: No results
```

### Step 3.5: Execute Migration Rollback

**Option A: Prisma Migrate Rollback (if migration has down migration)**

```bash
# Navigate to API Gateway directory
cd packages/backend/api-gateway

# Rollback one migration
npx prisma migrate resolve --rolled-back 20251116_140000_add_email_index

# Verify rollback
npx prisma migrate status
```

**Option B: Manual SQL Rollback**

```bash
# Create rollback SQL script
cat > rollback.sql << 'EOF'
-- Rollback migration: 20251116_140000_add_email_index
DROP INDEX IF EXISTS idx_users_email;

-- Verify rollback
\di idx_users_email;  -- Should show "Did not find any relation"
EOF

# Execute rollback
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres -f rollback.sql

# Verify migration table
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres \
  -c "DELETE FROM _prisma_migrations WHERE migration_name = '20251116_140000_add_email_index';"
```

**Option C: Restore from Backup (nuclear option)**

If migration caused severe corruption:
```bash
# See database-restore.md for full procedure
# Use the snapshot created in Step 3.3
```

### Step 3.6: Restart Application

```bash
# Scale services back up
kubectl scale deployment api-gateway --replicas=3 -n $NAMESPACE
kubectl scale deployment indexer --replicas=2 -n $NAMESPACE

# Verify pods are running
kubectl get pods -n $NAMESPACE

# Test database connectivity
curl -f https://api.ghost-protocol.io/health
```

### Step 3.7: Verify Database Integrity

```bash
# Run integrity checks
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres << 'EOF'

-- Check for orphaned records
SELECT COUNT(*) FROM users WHERE id NOT IN (SELECT user_id FROM transactions);

-- Check for null values in NOT NULL columns
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'users' AND is_nullable = 'NO' AND column_default IS NULL;

-- Verify row counts
SELECT 'users' AS table, COUNT(*) FROM users
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;

EOF
```

## Method 4: Frontend Rollback (S3/CloudFront)

**Use for:** Web frontend, Admin dashboard (React/Next.js apps)

**Estimated Time:** 5-10 minutes  
**Impact:** Brief user-facing changes, no downtime

### Step 4.1: Identify Previous Frontend Version

```bash
# List S3 versions of frontend assets
aws s3api list-object-versions \
  --bucket ghost-protocol-${ENVIRONMENT}-frontend \
  --prefix "build/" \
  --max-items 10 \
  --region $AWS_REGION

# Expected: List of versions with VersionId and LastModified
```

### Step 4.2: Restore Previous S3 Version

```bash
# Option A: Restore specific version
export VERSION_ID="abc123xyz"  # From previous step

# Copy all files from previous version
aws s3api list-object-versions \
  --bucket ghost-protocol-${ENVIRONMENT}-frontend \
  --prefix "build/" \
  --query "Versions[?VersionId=='${VERSION_ID}'].Key" \
  --output text | while read key; do
    aws s3api copy-object \
      --bucket ghost-protocol-${ENVIRONMENT}-frontend \
      --copy-source "ghost-protocol-${ENVIRONMENT}-frontend/${key}?versionId=${VERSION_ID}" \
      --key "$key" \
      --region $AWS_REGION
  done

# Option B: Redeploy from Git tag
git checkout v2.5.2  # Previous known-good version
cd packages/frontend/web
npm run build
aws s3 sync dist/ s3://ghost-protocol-${ENVIRONMENT}-frontend/build/ --delete
```

### Step 4.3: Invalidate CloudFront Cache

```bash
# Get CloudFront distribution ID
CLOUDFRONT_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='ghost-protocol-${ENVIRONMENT}-frontend'].Id" \
  --output text --region $AWS_REGION)

# Create cache invalidation
aws cloudfront create-invalidation \
  --distribution-id $CLOUDFRONT_ID \
  --paths "/*" \
  --region $AWS_REGION

# Expected: Invalidation ID and status "InProgress"
# Invalidation takes 5-10 minutes to propagate globally
```

### Step 4.4: Verify Frontend Rollback

```bash
# Wait 2-3 minutes for CloudFront invalidation to start propagating

# Test from multiple locations (use VPN or ask team members)
curl -I https://ghost-protocol.io/ | grep -i "x-cache"

# Expected: "x-cache: Miss from cloudfront" (cache invalidated)

# Test in browser (hard refresh: Ctrl+Shift+R / Cmd+Shift+R)
# Verify UI shows previous version (check version in footer or console)
```

**Browser Cache Clearing (for users):**
```markdown
If users still see old (broken) version:
1. Press Ctrl+Shift+Delete (Windows) or Cmd+Shift+Delete (Mac)
2. Select "Cached images and files"
3. Clear cache
4. Hard refresh page (Ctrl+F5 or Cmd+Shift+R)
```

## Method 5: Smart Contract Rollback/Emergency Actions

**Use for:** Deployed smart contracts (ERC-20 token, marketplace, etc.)

**Estimated Time:** 10-45 minutes  
**Impact:** Smart contract functionality may be paused

**⚠️ CRITICAL:** Smart contracts are immutable. You CANNOT truly "rollback" a deployed contract.

### Step 5.1: Assess Contract Issue

**Possible Issues:**
- Bug in contract logic (e.g., incorrect math, reentrancy vulnerability)
- Unauthorized access or exploit in progress
- Incorrect configuration (wrong admin address, wrong parameters)

**Available Actions:**
1. **Pause contract** (if pausable functionality exists)
2. **Deploy fixed contract** (new address, migrate state)
3. **Upgrade contract** (if using proxy pattern)
4. **Emergency withdrawal** (rescue funds if possible)

### Step 5.2: Pause Contract (Immediate Action)

**If contract has Pausable functionality:**

```bash
cd packages/contracts/marketplace

# Check if contract is pausable
npx hardhat verify-pausable --network mainnet --contract 0xCONTRACT_ADDRESS

# Pause contract immediately
npx hardhat pause --network mainnet --contract 0xCONTRACT_ADDRESS

# Expected: Transaction hash and confirmation
# Gas cost: ~50,000 gas (~$10-50 depending on gas price)
```

**Verify pause:**
```bash
npx hardhat call --network mainnet --contract 0xCONTRACT_ADDRESS --function "paused()"
# Expected: true
```

### Step 5.3: Deploy Fixed Contract (if needed)

```bash
# Option A: Deploy entirely new contract
npx hardhat deploy --network mainnet --contract MarketplaceV2

# Expected: New contract address 0xNEW_ADDRESS

# Option B: Upgrade via proxy (if using upgradeable contracts)
npx hardhat upgrade --network mainnet --proxy 0xPROXY_ADDRESS --implementation MarketplaceV2

# Expected: Transaction hash for upgrade
```

### Step 5.4: Migrate State (if applicable)

```bash
# If contract holds user funds or state that needs migration

# 1. Pause old contract (prevent new interactions)
# 2. Deploy new contract
# 3. Transfer admin privileges
# 4. Migrate user balances/state (may require multiple transactions)
# 5. Update frontend to point to new contract address
```

### Step 5.5: Update Frontend Contract Address

```bash
# Update environment variables
cd packages/frontend/web

# Update .env.production
echo "VITE_MARKETPLACE_CONTRACT_ADDRESS=0xNEW_ADDRESS" >> .env.production

# Rebuild and redeploy frontend
npm run build
aws s3 sync dist/ s3://ghost-protocol-prod-frontend/build/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"
```

### Step 5.6: Communication

**CRITICAL:** Smart contract changes must be communicated to users immediately.

```markdown
🚨 SMART CONTRACT SECURITY UPDATE 🚨

We have paused the marketplace smart contract (0xOLD_ADDRESS) due to a critical bug.

**What this means:**
- All marketplace transactions are temporarily paused
- Your funds are safe and secure
- No user action required

**Next steps:**
- We are deploying a fixed contract
- ETA: 30 minutes
- We will update the frontend automatically
- You may need to refresh your browser after the update

**New contract address:** 0xNEW_ADDRESS (deployed at 15:30 UTC)

Thank you for your patience. 🙏
```

## Post-Rollback Validation

**Comprehensive validation checklist:**

### Backend Services
```bash
# Pod health
kubectl get pods -n $NAMESPACE
# Expected: All pods Running and Ready

# Service endpoints
kubectl get endpoints -n $NAMESPACE
# Expected: All services have active endpoints

# API health
curl -f https://api.ghost-protocol.io/health
# Expected: {"status":"ok"}

# Error rate (Grafana)
# https://grafana.ghost-protocol.io/d/api-overview
# Expected: Error rate <1%

# Response time
# Expected: p95 <500ms, p99 <1s
```

### Frontend
```bash
# CloudFront distribution status
aws cloudfront get-distribution --id $CLOUDFRONT_ID \
  --query 'Distribution.Status' --output text
# Expected: Deployed

# Website accessibility
curl -I https://ghost-protocol.io/
# Expected: 200 OK

# JavaScript console errors
# Open browser DevTools → Console
# Expected: No critical errors
```

### Database
```bash
# Connection test
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres -c "SELECT 1;"
# Expected: 1

# Active connections
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres \
  -c "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';"
# Expected: Normal range (5-50 depending on load)

# No locks
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres \
  -c "SELECT COUNT(*) FROM pg_locks WHERE granted = false;"
# Expected: 0 (no blocked queries)
```

## Post-Rollback Analysis

### Step A.1: Document Rollback Details

```markdown
# Rollback Report: [Date]

**Rolled Back Component:** API Gateway v2.5.3 → v2.5.2
**Reason:** High error rate (>20%) due to null pointer exception
**Rollback Method:** Kubernetes rollout undo
**Duration:** 14:32 - 14:48 UTC (16 minutes)
**Impact:** 100% of users affected during incident, 0% during rollback

**Timeline:**
- 14:32: Deployment v2.5.3 completed
- 14:35: Error rate spike detected
- 14:40: Decision to rollback made
- 14:42: Rollback initiated
- 14:48: Rollback completed, service restored

**Root Cause:** Missing null check in JWT parsing code

**Prevention:**
- Add test coverage for edge cases
- Implement canary deployments
- Enable auto-rollback on error threshold
```

### Step A.2: Create Post-Mortem (for P0/P1 incidents)

See **incident-response.md** for full post-mortem template.

### Step A.3: Update Deployment Process

```bash
# Add safeguards to prevent similar issues

# 1. Enable canary deployments
# packages/tooling/scripts/deploy-canary.sh

# 2. Add automated rollback on error threshold
# infra/k8s/base/api-gateway/hpa.yaml (add error-based autoscaling)

# 3. Improve test coverage
# Add tests for edge cases that caused the issue

# 4. Update CI/CD pipeline
# Add smoke tests after deployment, before rolling out to 100%
```

## Troubleshooting

### Issue: Rollback Fails - Pods Still CrashLoopBackOff

**Symptom:** After rollback, pods still failing to start

**Cause:** Likely database schema incompatibility or configuration issue

**Solution:**
```bash
# Check pod logs for specific error
kubectl logs -n $NAMESPACE -l app=api-gateway --tail=100

# Common causes:
# - Database migration not rolled back → Roll back migration separately
# - Environment variable misconfiguration → Check ConfigMap/Secrets
# - Persistent volume issue → Check PVC status

# Nuclear option: Delete pods and let them recreate
kubectl delete pod -n $NAMESPACE -l app=api-gateway
```

### Issue: Terraform Rollback Stuck

**Symptom:** `terraform apply` hangs or times out

**Cause:** Resource dependencies or AWS API throttling

**Solution:**
```bash
# Check Terraform logs for specific resource stuck
# Usually seen with EKS, RDS, or VPC resources

# Option 1: Increase timeout
terraform apply -lock-timeout=30m rollback.tfplan

# Option 2: Target specific resources
terraform apply -target=module.compute.aws_eks_node_group.main rollback.tfplan

# Option 3: Manual intervention via AWS Console
# Identify stuck resource and resolve manually, then refresh Terraform state
terraform refresh -var-file=environments/${ENVIRONMENT}/terraform.tfvars
```

### Issue: Database Migration Rollback Creates Orphaned Data

**Symptom:** After migration rollback, application errors about missing columns/tables

**Cause:** Application code still expects new schema

**Solution:**
```bash
# You must rollback BOTH database AND application code

# 1. Rollback application first (to version that works with old schema)
kubectl rollout undo deployment/api-gateway -n $NAMESPACE

# 2. Then rollback database migration
npx prisma migrate resolve --rolled-back <migration-name>

# Order matters: Always rollback app code before rolling back database
```

## Prevention Best Practices

### 1. Implement Canary Deployments

```yaml
# Example: Deploy to 10% of pods first, monitor, then roll out to 100%
# See: infra/k8s/base/api-gateway/canary-deployment.yaml
```

### 2. Enable Auto-Rollback on Error Threshold

```bash
# Use tools like Flagger or Argo Rollouts for automated canary + rollback
# If error rate >5% for 5 minutes → auto-rollback
```

### 3. Implement Blue-Green Deployments

```bash
# For critical services, maintain two environments
# Route traffic only after validation on "green" environment
```

### 4. Database Migration Safety

```bash
# Always include "down" migrations in Prisma schema
# Test rollback in staging before applying to production
# Never drop columns/tables without multi-step migration:
#   Step 1: Make column nullable (deploy code that doesn't use it)
#   Step 2: Drop column (after verifying code doesn't use it)
```

### 5. Deployment Checklist

Before every production deployment:
- [ ] Tested in staging environment
- [ ] Database migrations have rollback scripts
- [ ] Canary deployment configured (if available)
- [ ] Rollback procedure documented
- [ ] On-call engineer notified
- [ ] Deployment window scheduled (low-traffic hours)
- [ ] Monitoring dashboards open and watched

## References

- **Kubernetes Deployments:** https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- **Terraform State Management:** https://www.terraform.io/docs/language/state/index.html
- **Prisma Migrations:** https://www.prisma.io/docs/concepts/components/prisma-migrate
- **CloudFront Invalidation:** https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-16 | DevOps Team | Initial version |

