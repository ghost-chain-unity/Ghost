# RDS PostgreSQL Database Restore Procedure

## Overview

This runbook provides comprehensive procedures for restoring the Ghost Protocol RDS PostgreSQL database from various backup sources.

**Severity:** Critical  
**Estimated Time:** 30 minutes - 4 hours (depending on restore type and database size)  
**Last Updated:** 2025-11-16

## When to Use This Runbook

Database restore is required in these scenarios:

- **Data Corruption:** Malformed data, schema corruption, transaction anomalies
- **Accidental Data Deletion:** DROP TABLE, DELETE without WHERE, TRUNCATE
- **Ransomware/Security Breach:** Database encrypted or compromised
- **Application Bug:** Bad migration or code introduced data inconsistencies
- **Disaster Recovery:** Primary region failure, complete infrastructure loss
- **Testing/Validation:** Restore to staging for investigation

## Backup Types Available

### 1. Automated Snapshots (RDS)
- **Retention:** 7 days (configurable up to 35 days)
- **Frequency:** Daily during maintenance window
- **RPO (Recovery Point Objective):** Up to 24 hours
- **Location:** Same region as source DB
- **Cost:** Included in RDS pricing

### 2. Manual Snapshots (RDS)
- **Retention:** Indefinite (until manually deleted)
- **Frequency:** Created manually or via automation
- **RPO:** Depends on snapshot frequency
- **Location:** Same region (can copy cross-region)
- **Cost:** $0.095 per GB-month

### 3. Point-in-Time Recovery (PITR)
- **Retention:** Up to 35 days (based on automated backup retention)
- **Granularity:** 5-minute increments
- **RPO:** As low as 5 minutes
- **Location:** Same region
- **Cost:** Transaction log storage

### 4. pg_dump Backups (S3)
- **Retention:** 90 days (configurable)
- **Frequency:** Daily via cron job
- **RPO:** Up to 24 hours
- **Location:** S3 (cross-region replicated)
- **Cost:** S3 storage costs

## Prerequisites

### Required Access
- AWS Console access (RDS, S3, EC2 permissions)
- Database admin credentials (master user)
- kubectl access (to stop application pods)
- Terraform access (for infrastructure changes)
- PagerDuty/Slack access (for notifications)

### Required Tools
```bash
aws --version          # AWS CLI v2.x
psql --version         # PostgreSQL client 14+
kubectl version        # kubectl 1.28+
terraform --version    # Terraform 1.5+
```

### Environment Variables
```bash
export AWS_REGION="us-east-1"
export ENVIRONMENT="prod"  # or dev/staging
export DB_IDENTIFIER="ghost-protocol-${ENVIRONMENT}-db"
export CLUSTER_NAME="ghost-protocol-${ENVIRONMENT}"
export NAMESPACE="ghost-protocol-${ENVIRONMENT}"
```

## Critical: Pre-Restore Checklist

**⚠️ STOP! Complete this checklist before proceeding with ANY restore operation.**

### 1. Incident Documentation
```bash
# Create incident ticket in PagerDuty
# Document:
# - What happened (data loss, corruption, breach)
# - When it was detected (exact timestamp)
# - What data is affected
# - Restore target time (if known)
```

### 2. Stakeholder Notification

**Notify immediately:**
- [ ] Engineering Manager
- [ ] CTO (for production restores)
- [ ] Product team (user impact assessment)
- [ ] Customer support (user communication)
- [ ] Legal/compliance (for security breaches)

**Post in Slack #incidents:**
```
🚨 DATABASE RESTORE IN PROGRESS 🚨
Environment: Production
Issue: [Brief description]
ETA: [Estimated completion time]
Impact: [Service downtime expected/not expected]
Point of Contact: [Your name]
```

### 3. Stop Application Writes

**CRITICAL:** Prevent data inconsistency during restore

```bash
# Scale down all write-capable services
kubectl scale deployment api-gateway --replicas=0 -n $NAMESPACE
kubectl scale deployment indexer --replicas=0 -n $NAMESPACE
kubectl scale deployment rpc-orchestrator --replicas=0 -n $NAMESPACE

# Verify no pods are running
kubectl get pods -n $NAMESPACE

# Expected: No api-gateway, indexer, or rpc-orchestrator pods
```

### 4. Backup Current State (Even If Corrupted)

```bash
# Create a final manual snapshot before restore
BACKUP_SNAPSHOT="ghost-protocol-${ENVIRONMENT}-pre-restore-$(date +%Y%m%d-%H%M%S)"

aws rds create-db-snapshot \
  --db-instance-identifier $DB_IDENTIFIER \
  --db-snapshot-identifier $BACKUP_SNAPSHOT \
  --region $AWS_REGION

# Wait for snapshot to complete (5-30 minutes depending on size)
aws rds wait db-snapshot-completed \
  --db-snapshot-identifier $BACKUP_SNAPSHOT \
  --region $AWS_REGION

echo "Backup snapshot created: $BACKUP_SNAPSHOT"
```

**Why:** This gives you a rollback point if the restore doesn't fix the issue or makes it worse.

### 5. Identify Restore Target Time

```bash
# For accidental deletion - identify exact time BEFORE the incident
# Example: Data deleted at 2025-11-16 14:32:00 UTC
# Restore target: 2025-11-16 14:30:00 UTC (2 minutes before)

export RESTORE_TARGET_TIME="2025-11-16T14:30:00Z"

# For corruption - identify last known good time
# Check application logs, CloudWatch, or user reports
```

### 6. Calculate Downtime Window

```bash
# Estimated restore times:
# - Automated snapshot: 20-40 minutes
# - Manual snapshot: 20-40 minutes
# - PITR: 30-60 minutes (depends on transaction log size)
# - pg_restore from S3: 1-4 hours (depends on dump size)

# Add 30 minutes for validation and service restart
# Total downtime window: [Restore time] + 30 minutes
```

## Decision Tree: Which Restore Method?

```
Database Issue Detected
    │
    ├─ Do you know EXACT time of data loss/corruption?
    │   ├─ Yes, within last 35 days
    │   │   └─ Use Method 3: Point-in-Time Recovery (PITR) ✅ RECOMMENDED
    │   └─ No/Unsure
    │       ├─ Need data from >35 days ago?
    │       │   └─ Use Method 4: Restore from S3 pg_dump
    │       └─ Need most recent backup?
    │           └─ Use Method 1: Restore from Automated Snapshot
    │
    ├─ Is this a cross-region disaster?
    │   └─ Yes → Use Method 5: Cross-Region Disaster Recovery
    │
    └─ Is this for testing/investigation only?
        └─ Yes → Use Method 2: Restore Manual Snapshot (no production impact)
```

## Method 1: Restore from Automated Snapshot

**Use when:** You need to restore to the most recent daily backup

**RPO:** Up to 24 hours  
**RTO:** 30-60 minutes  
**Data Loss:** Up to 1 day of data

### Step 1.1: List Available Automated Snapshots

```bash
# List automated snapshots for the database
aws rds describe-db-snapshots \
  --db-instance-identifier $DB_IDENTIFIER \
  --snapshot-type automated \
  --region $AWS_REGION \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,Status]' \
  --output table

# Expected: List of snapshots from last 7 days (or retention period)
```

### Step 1.2: Select Snapshot

```bash
# Choose the most recent snapshot (or specific date)
export SNAPSHOT_ID="rds:ghost-protocol-prod-db-2025-11-16-04-00"

# Verify snapshot is available
aws rds describe-db-snapshots \
  --db-snapshot-identifier $SNAPSHOT_ID \
  --region $AWS_REGION \
  --query 'DBSnapshots[0].[Status,SnapshotCreateTime,AllocatedStorage]'

# Expected Status: "available"
```

### Step 1.3: Restore from Snapshot

**Option A: Restore to New Instance (RECOMMENDED for production)**

```bash
# Restore to a new RDS instance for validation
export RESTORE_DB_IDENTIFIER="${DB_IDENTIFIER}-restored-$(date +%Y%m%d-%H%M%S)"

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --db-snapshot-identifier $SNAPSHOT_ID \
  --db-instance-class db.r5.large \
  --db-subnet-group-name ghost-protocol-${ENVIRONMENT}-db-subnet-group \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --no-publicly-accessible \
  --enable-iam-database-authentication \
  --region $AWS_REGION

# Wait for restore to complete (20-40 minutes)
aws rds wait db-instance-available \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --region $AWS_REGION

echo "Restore complete: $RESTORE_DB_IDENTIFIER"
```

**Option B: Replace Existing Instance (DESTRUCTIVE)**

⚠️ **WARNING:** This deletes the current instance. Only use if you have a pre-restore backup.

```bash
# Delete current database instance
aws rds delete-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --skip-final-snapshot \
  --region $AWS_REGION

# Wait for deletion (10-20 minutes)
aws rds wait db-instance-deleted \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $AWS_REGION

# Restore with original identifier
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier $DB_IDENTIFIER \
  --db-snapshot-identifier $SNAPSHOT_ID \
  --db-instance-class db.r5.large \
  --db-subnet-group-name ghost-protocol-${ENVIRONMENT}-db-subnet-group \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --no-publicly-accessible \
  --enable-iam-database-authentication \
  --region $AWS_REGION

aws rds wait db-instance-available --db-instance-identifier $DB_IDENTIFIER --region $AWS_REGION
```

### Step 1.4: Validation

Continue to **Section: Post-Restore Validation** below.

## Method 2: Restore from Manual Snapshot

**Use when:** You need a specific backup created manually (e.g., before a migration)

**Process:** Identical to Method 1, but list manual snapshots:

```bash
# List manual snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier $DB_IDENTIFIER \
  --snapshot-type manual \
  --region $AWS_REGION \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,Status]' \
  --output table

# Select specific snapshot
export SNAPSHOT_ID="ghost-protocol-prod-pre-migration-20251115"

# Follow Method 1 steps 1.3 and 1.4
```

## Method 3: Point-in-Time Recovery (PITR) - RECOMMENDED

**Use when:** You know the exact time before data loss/corruption

**RPO:** 5 minutes  
**RTO:** 40-90 minutes  
**Data Loss:** Minimal (5 minutes max)

### Step 3.1: Verify PITR is Enabled

```bash
# Check if automated backups are enabled
aws rds describe-db-instances \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $AWS_REGION \
  --query 'DBInstances[0].[BackupRetentionPeriod,LatestRestorableTime]'

# Expected:
# - BackupRetentionPeriod: 7 (or higher)
# - LatestRestorableTime: Recent timestamp (within last 5-10 minutes)
```

### Step 3.2: Determine Restore Target Time

```bash
# Identify the exact time BEFORE the incident
# Example scenarios:

# Scenario A: Accidental DELETE at 14:32 UTC
export RESTORE_TARGET_TIME="2025-11-16T14:30:00Z"  # 2 min before

# Scenario B: Bad migration deployed at 09:15 UTC
export RESTORE_TARGET_TIME="2025-11-16T09:14:00Z"  # 1 min before

# Scenario C: Corruption detected at 16:00, last known good at 15:45
export RESTORE_TARGET_TIME="2025-11-16T15:45:00Z"

# Verify target time is within restorable range
aws rds describe-db-instances \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $AWS_REGION \
  --query 'DBInstances[0].[EarliestRestorableTime,LatestRestorableTime]'
```

### Step 3.3: Restore to Specific Point in Time

```bash
# Restore to new instance (RECOMMENDED)
export RESTORE_DB_IDENTIFIER="${DB_IDENTIFIER}-pitr-$(date +%Y%m%d-%H%M%S)"

aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier $DB_IDENTIFIER \
  --target-db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --restore-time $RESTORE_TARGET_TIME \
  --db-instance-class db.r5.large \
  --db-subnet-group-name ghost-protocol-${ENVIRONMENT}-db-subnet-group \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --no-publicly-accessible \
  --enable-iam-database-authentication \
  --region $AWS_REGION

# Wait for restore (30-60 minutes)
aws rds wait db-instance-available \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --region $AWS_REGION

echo "PITR restore complete: $RESTORE_DB_IDENTIFIER"
```

### Step 3.4: Validation

Continue to **Section: Post-Restore Validation** below.

## Method 4: Restore from S3 pg_dump Backup

**Use when:** Need backup older than RDS retention (7-35 days)

**RPO:** Up to 24 hours  
**RTO:** 1-4 hours (depends on dump size)

### Step 4.1: List Available S3 Backups

```bash
# List backups in S3
export BACKUP_BUCKET="ghost-protocol-${ENVIRONMENT}-backups"

aws s3 ls s3://${BACKUP_BUCKET}/database/postgresql/ --recursive --human-readable

# Expected output:
# 2025-11-16 04:00:00   2.5 GB database/postgresql/ghost-protocol-prod-20251116-040000.sql.gz
# 2025-11-15 04:00:00   2.4 GB database/postgresql/ghost-protocol-prod-20251115-040000.sql.gz
```

### Step 4.2: Download Backup File

```bash
# Select backup file
export BACKUP_FILE="ghost-protocol-prod-20251115-040000.sql.gz"

# Download from S3 (may take 10-30 minutes for large files)
aws s3 cp s3://${BACKUP_BUCKET}/database/postgresql/${BACKUP_FILE} /tmp/${BACKUP_FILE}

# Verify download
ls -lh /tmp/${BACKUP_FILE}

# Decompress
gunzip /tmp/${BACKUP_FILE}
# Result: /tmp/ghost-protocol-prod-20251115-040000.sql
```

### Step 4.3: Prepare Target Database

```bash
# Option A: Create new RDS instance for restore
export RESTORE_DB_IDENTIFIER="${DB_IDENTIFIER}-s3restore-$(date +%Y%m%d-%H%M%S)"

aws rds create-db-instance \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --db-instance-class db.r5.large \
  --engine postgres \
  --engine-version 14.9 \
  --master-username ghostadmin \
  --master-user-password "$(aws secretsmanager get-secret-value --secret-id ghost-protocol/${ENVIRONMENT}/db-password --query SecretString --output text)" \
  --allocated-storage 100 \
  --db-subnet-group-name ghost-protocol-${ENVIRONMENT}-db-subnet-group \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --backup-retention-period 7 \
  --no-publicly-accessible \
  --enable-iam-database-authentication \
  --region $AWS_REGION

# Wait for database to be available
aws rds wait db-instance-available --db-instance-identifier $RESTORE_DB_IDENTIFIER --region $AWS_REGION

# Get endpoint
RESTORE_DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --region $AWS_REGION \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "Restore target endpoint: $RESTORE_DB_ENDPOINT"
```

### Step 4.4: Restore SQL Dump

```bash
# Connect from a bastion host or EKS pod with psql installed
# Get database password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ghost-protocol/${ENVIRONMENT}/db-password \
  --query SecretString --output text)

# Restore database (may take 1-3 hours for large dumps)
PGPASSWORD=$DB_PASSWORD psql \
  -h $RESTORE_DB_ENDPOINT \
  -U ghostadmin \
  -d postgres \
  -f /tmp/ghost-protocol-prod-20251115-040000.sql

# Monitor progress in another terminal
watch -n 30 "PGPASSWORD=$DB_PASSWORD psql -h $RESTORE_DB_ENDPOINT -U ghostadmin -d postgres -c '\dt'"
```

### Step 4.5: Validation

Continue to **Section: Post-Restore Validation** below.

## Method 5: Cross-Region Disaster Recovery

**Use when:** Primary region is unavailable

See **disaster-recovery.md** runbook for full cross-region failover procedure.

## Post-Restore Validation

**CRITICAL:** Validate restored data before switching application traffic!

### Step V.1: Get Restored Database Endpoint

```bash
# Get endpoint of restored database
RESTORE_DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --region $AWS_REGION \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "Restored DB endpoint: $RESTORE_DB_ENDPOINT"
```

### Step V.2: Connection Test

```bash
# Test database connection
PGPASSWORD=$DB_PASSWORD psql \
  -h $RESTORE_DB_ENDPOINT \
  -U ghostadmin \
  -d postgres \
  -c "SELECT version();"

# Expected: PostgreSQL version info
```

### Step V.3: Data Integrity Checks

```bash
# Run data integrity queries
PGPASSWORD=$DB_PASSWORD psql -h $RESTORE_DB_ENDPOINT -U ghostadmin -d postgres << EOF

-- Check row counts
SELECT 'users' AS table_name, COUNT(*) FROM users
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'smart_contracts', COUNT(*) FROM smart_contracts;

-- Check for expected data (example: verify specific record exists)
SELECT id, created_at, updated_at FROM users WHERE id = 'known-user-id';

-- Check latest transaction timestamp (verify restore point)
SELECT MAX(created_at) AS latest_transaction FROM transactions;

-- Verify schema version (Prisma migrations)
SELECT * FROM "_prisma_migrations" ORDER BY finished_at DESC LIMIT 5;

EOF
```

**Validation Checklist:**
- [ ] Row counts match expectations (or close to target restore time)
- [ ] Critical records exist (test known user IDs, transactions)
- [ ] Latest timestamp is BEFORE the incident (confirms correct restore point)
- [ ] Schema version matches expected state
- [ ] No obvious data corruption (null values, foreign key violations)

### Step V.4: Application Connection Test

```bash
# Update database endpoint in application temporarily
# Create a test pod with new database connection

kubectl run db-test --rm -it --restart=Never \
  --image=postgres:14 \
  --env="PGHOST=$RESTORE_DB_ENDPOINT" \
  --env="PGUSER=ghostadmin" \
  --env="PGPASSWORD=$DB_PASSWORD" \
  --env="PGDATABASE=postgres" \
  --command -- psql -c "SELECT COUNT(*) FROM users;"
```

### Step V.5: Smoke Test Application (Staging First)

If restoring production, test with staging first:

```bash
# Update staging database connection to point to restored instance
kubectl set env deployment/api-gateway \
  DATABASE_URL="postgresql://ghostadmin:${DB_PASSWORD}@${RESTORE_DB_ENDPOINT}:5432/postgres" \
  -n ghost-protocol-staging

# Wait for pods to restart
kubectl rollout status deployment/api-gateway -n ghost-protocol-staging

# Test API endpoints
curl https://staging-api.ghost-protocol.io/health
curl https://staging-api.ghost-protocol.io/api/v1/users/me \
  -H "Authorization: Bearer <test-token>"
```

## Cutover to Restored Database

**⚠️ This step switches production traffic to the restored database**

### Option A: Promote Restored Instance (Rename)

```bash
# 1. Stop application pods (if not already stopped)
kubectl scale deployment api-gateway --replicas=0 -n $NAMESPACE
kubectl scale deployment indexer --replicas=0 -n $NAMESPACE
kubectl scale deployment rpc-orchestrator --replicas=0 -n $NAMESPACE

# 2. Rename current database instance (to keep as backup)
aws rds modify-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --new-db-instance-identifier "${DB_IDENTIFIER}-old-$(date +%Y%m%d)" \
  --apply-immediately \
  --region $AWS_REGION

# Wait for rename (5-10 minutes)
aws rds wait db-instance-available \
  --db-instance-identifier "${DB_IDENTIFIER}-old-$(date +%Y%m%d)" \
  --region $AWS_REGION

# 3. Rename restored instance to production identifier
aws rds modify-db-instance \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --new-db-instance-identifier $DB_IDENTIFIER \
  --apply-immediately \
  --region $AWS_REGION

# Wait for rename
aws rds wait db-instance-available \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $AWS_REGION

# 4. Restart application pods (they will connect to "new" database with same endpoint)
kubectl scale deployment api-gateway --replicas=3 -n $NAMESPACE
kubectl scale deployment indexer --replicas=2 -n $NAMESPACE
kubectl scale deployment rpc-orchestrator --replicas=2 -n $NAMESPACE
```

### Option B: Update Application Connection String

```bash
# Update Kubernetes secrets with new database endpoint
kubectl create secret generic database-credentials \
  --from-literal=DATABASE_URL="postgresql://ghostadmin:${DB_PASSWORD}@${RESTORE_DB_ENDPOINT}:5432/postgres" \
  --dry-run=client -o yaml | kubectl apply -n $NAMESPACE -f -

# Restart deployments to pick up new secret
kubectl rollout restart deployment/api-gateway -n $NAMESPACE
kubectl rollout restart deployment/indexer -n $NAMESPACE
kubectl rollout restart deployment/rpc-orchestrator -n $NAMESPACE

# Monitor rollout
kubectl rollout status deployment/api-gateway -n $NAMESPACE
```

## Post-Cutover Validation

```bash
# Check application logs
kubectl logs -n $NAMESPACE -l app=api-gateway --tail=100

# Test API health
curl -f https://api.ghost-protocol.io/health

# Monitor error rates in Grafana
# https://grafana.ghost-protocol.io/d/api-overview

# Check database connections
PGPASSWORD=$DB_PASSWORD psql -h $RESTORE_DB_ENDPOINT -U ghostadmin -d postgres \
  -c "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';"
```

## Rollback Procedure (If Restore Fails)

If the restored database doesn't work or has issues:

### Step R.1: Revert to Original Database

```bash
# If using Option A (renamed original):
# 1. Stop applications
kubectl scale deployment api-gateway --replicas=0 -n $NAMESPACE
kubectl scale deployment indexer --replicas=0 -n $NAMESPACE

# 2. Delete failed restore instance
aws rds delete-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --skip-final-snapshot \
  --region $AWS_REGION

# 3. Rename original back
aws rds modify-db-instance \
  --db-instance-identifier "${DB_IDENTIFIER}-old-$(date +%Y%m%d)" \
  --new-db-instance-identifier $DB_IDENTIFIER \
  --apply-immediately \
  --region $AWS_REGION

# 4. Restart applications
kubectl scale deployment api-gateway --replicas=3 -n $NAMESPACE
```

### Step R.2: Notify Stakeholders

```bash
# Post in Slack #incidents
# Subject: Database restore rollback completed
# Details: Reverted to original database, restore did not fix issue
```

## Troubleshooting

### Issue: Restore Takes Longer Than Expected

**Symptom:** `aws rds wait` command times out

**Solution:**
```bash
# Check restore progress
aws rds describe-db-instances \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --region $AWS_REGION \
  --query 'DBInstances[0].[DBInstanceStatus,BackupRetentionPeriod]'

# Status progression: creating → backing-up → available
# Large databases (>100GB) can take 60-90 minutes
```

### Issue: Restored Database Has Wrong Data

**Symptom:** Restored data doesn't match expected restore point

**Cause:** Wrong snapshot selected or PITR time incorrect

**Solution:**
```bash
# Verify restore source
aws rds describe-db-instances \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --region $AWS_REGION \
  --query 'DBInstances[0].[DBInstanceIdentifier,LatestRestorableTime]'

# If wrong, delete and re-restore with correct snapshot/time
aws rds delete-db-instance --db-instance-identifier $RESTORE_DB_IDENTIFIER --skip-final-snapshot --region $AWS_REGION
```

### Issue: Application Can't Connect After Restore

**Symptom:** Application shows database connection errors

**Solution:**
```bash
# Check security group rules
aws rds describe-db-instances \
  --db-instance-identifier $RESTORE_DB_IDENTIFIER \
  --query 'DBInstances[0].VpcSecurityGroups'

# Verify endpoint is correct
kubectl get secret database-credentials -n $NAMESPACE -o jsonpath='{.data.DATABASE_URL}' | base64 -d

# Test connection from within cluster
kubectl run db-test --rm -it --restart=Never --image=postgres:14 \
  --env="DATABASE_URL=postgresql://..." \
  -- psql $DATABASE_URL -c "SELECT 1"
```

## Prevention and Best Practices

### 1. Regular Backup Testing

```bash
# Quarterly: Restore production snapshot to staging
# Verify application functionality with restored data
# Document any issues or gaps
```

### 2. Increase Automated Backup Retention

```bash
# For production, consider 35-day retention
aws rds modify-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --backup-retention-period 35 \
  --apply-immediately \
  --region $AWS_REGION
```

### 3. Create Manual Snapshots Before Risky Changes

```bash
# Before major migrations, schema changes, or releases
aws rds create-db-snapshot \
  --db-instance-identifier $DB_IDENTIFIER \
  --db-snapshot-identifier "${DB_IDENTIFIER}-pre-migration-$(date +%Y%m%d)" \
  --region $AWS_REGION
```

### 4. Monitor Backup Success

```bash
# Set up CloudWatch alarms for failed backups
aws cloudwatch put-metric-alarm \
  --alarm-name rds-backup-failed-${ENVIRONMENT} \
  --alarm-description "Alert when RDS automated backup fails" \
  --metric-name BackupDurationInSeconds \
  --namespace AWS/RDS \
  --statistic Maximum \
  --period 86400 \
  --threshold 0 \
  --comparison-operator LessThanThreshold \
  --evaluation-periods 1
```

## References

- **Terraform Module:** `infra/terraform/modules/database/aws/main.tf`
- **RDS Replica Config:** `infra/terraform/modules/database/aws/replicas.tf`
- **Backup Scripts:** `packages/tooling/scripts/backup-database.sh`
- **AWS RDS Documentation:** https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_CommonTasks.BackupRestore.html
- **PostgreSQL Backup Guide:** https://www.postgresql.org/docs/current/backup.html

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-16 | DevOps Team | Initial version |

