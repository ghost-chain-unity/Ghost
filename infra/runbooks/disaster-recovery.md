# Disaster Recovery Procedure

## Overview

This runbook provides comprehensive procedures for recovering the Ghost Protocol infrastructure from catastrophic failures including region outages, complete data loss, and security breaches.

**Severity:** Critical  
**Recovery Time Objective (RTO):** < 4 hours  
**Recovery Point Objective (RPO):** < 1 hour  
**Last Updated:** 2025-11-16

## Disaster Scenarios

### Scenario 1: AWS Region Failure (Primary: us-east-1)

**Characteristics:**
- Complete loss of EKS cluster, RDS, S3 in primary region
- AWS declares region unavailable or severely degraded
- All services in us-east-1 inaccessible

**Impact:** Complete service outage until failover to secondary region  
**RTO:** 2-4 hours  
**RPO:** < 1 hour (database replication lag)

### Scenario 2: Complete Data Loss / Ransomware

**Characteristics:**
- Database encrypted or corrupted by ransomware
- S3 buckets deleted or encrypted
- Backups compromised or deleted
- Requires restoration from offline/immutable backups

**Impact:** Complete service outage, potential data loss  
**RTO:** 4-8 hours  
**RPO:** Up to 24 hours (depending on backup age)

### Scenario 3: Critical Security Breach

**Characteristics:**
- Unauthorized access to infrastructure (AWS account compromised)
- Data exfiltration detected or suspected
- Need to rebuild entire infrastructure from scratch
- Forensic investigation required

**Impact:** Complete service shutdown for security  
**RTO:** 8-24 hours (includes forensics)  
**RPO:** Variable (depends on breach timing)

### Scenario 4: Cascading Infrastructure Failure

**Characteristics:**
- Multiple critical components failing simultaneously
- Terraform state corrupted or locked
- Unable to apply infrastructure changes
- Circular dependencies preventing recovery

**Impact:** Degraded or complete service outage  
**RTO:** 2-6 hours  
**RPO:** Minimal (no data loss expected)

## Prerequisites

### Required Access (Emergency Access)

**Critical Access Requirements:**
- AWS root account credentials (stored in company vault)
- Secondary AWS account (disaster recovery account in us-west-2)
- Terraform Cloud/Enterprise admin access
- GitHub repository admin access (for infrastructure code)
- Domain registrar access (for DNS changes)
- Emergency contact list with phone numbers

### Emergency Contact List

```markdown
| Role | Name | Primary Contact | Backup Contact |
|------|------|-----------------|----------------|
| CTO | Michael Chen | +1-XXX-XXX-XXXX | michael@ghost-protocol.io |
| VP Engineering | Alice Johnson | +1-XXX-XXX-XXXX | alice@ghost-protocol.io |
| Senior SRE | John Doe | +1-XXX-XXX-XXXX | john@ghost-protocol.io |
| AWS TAM | Jane Smith (AWS) | +1-XXX-XXX-XXXX | aws-support case |
| Database Admin | Bob Wilson | +1-XXX-XXX-XXXX | bob@ghost-protocol.io |
| Security Lead | Sarah Davis | +1-XXX-XXX-XXXX | sarah@ghost-protocol.io |
```

### Required Tools

```bash
aws --version          # AWS CLI v2.x
terraform --version    # Terraform 1.5+
kubectl version        # kubectl 1.28+
psql --version         # PostgreSQL client 14+
git --version          # Git 2.x
jq --version           # jq for JSON parsing
```

### Disaster Recovery Assets

**Pre-Configured Resources (us-west-2):**
- DR EKS cluster: `ghost-protocol-dr-cluster`
- DR RDS read replica: `ghost-protocol-dr-db`
- DR S3 buckets: `ghost-protocol-dr-*`
- DR Terraform state: `ghost-protocol-dr-terraform-state`

## Decision Tree: Disaster Type

```
Disaster Detected
    │
    ├─ Is primary region (us-east-1) completely unavailable?
    │   └─ Yes → SCENARIO A: Regional Failover (RTO: 2-4 hours)
    │
    ├─ Is database corrupted/encrypted (ransomware)?
    │   └─ Yes → SCENARIO B: Data Recovery from Backups (RTO: 4-8 hours)
    │
    ├─ Is there a security breach (AWS account compromised)?
    │   └─ Yes → SCENARIO C: Security Incident Recovery (RTO: 8-24 hours)
    │
    ├─ Is infrastructure broken but data intact?
    │   └─ Yes → SCENARIO D: Infrastructure Rebuild (RTO: 2-6 hours)
    │
    └─ Multiple components failing?
        └─ Escalate to CTO, declare major incident, follow SCENARIO A
```

## SCENARIO A: Regional Failover (Primary Region Failure)

**Use when:** AWS us-east-1 region is completely unavailable

**RTO:** 2-4 hours  
**RPO:** < 1 hour

### Phase A.1: Declare Disaster (< 5 minutes)

```bash
# 1. Verify region is actually down (not just isolated issue)
aws ec2 describe-regions --region us-east-1
# Expected: Timeout or error if region is down

# Check AWS Service Health Dashboard
# https://health.aws.amazon.com/health/status

# 2. Create emergency incident
# PagerDuty: Create P0 incident "AWS us-east-1 Region Failure - DR Activated"

# 3. Emergency notification
# Slack: Post in #critical-incidents
# Email: Send to emergency contact list
# Status Page: Update public status page
```

**Emergency Notification Template:**

```markdown
🚨 DISASTER RECOVERY ACTIVATED 🚨

**Event:** AWS us-east-1 Region Complete Failure
**Time:** 2025-11-16 14:00 UTC
**Status:** FAILOVER TO DR REGION IN PROGRESS
**Incident Commander:** John Doe
**Estimated Recovery:** 14:00 + 4 hours = 18:00 UTC

**Actions:**
1. Confirmed us-east-1 region unavailable (AWS Health Dashboard)
2. Activating disaster recovery plan
3. Failing over to us-west-2 secondary region
4. Database failover in progress

**Impact:**
- Complete service outage (100% of users affected)
- Estimated downtime: 2-4 hours
- No data loss expected (database replicated)

**Communication:**
- Status updates every 30 minutes
- Next update: 14:30 UTC

DO NOT attempt to access production resources. All hands on deck.
```

### Phase A.2: Promote DR Database (15-30 minutes)

**Critical Path:** Database must be promoted first

```bash
# Set environment for DR region
export AWS_REGION="us-west-2"
export DR_REGION="us-west-2"
export DR_DB_IDENTIFIER="ghost-protocol-dr-db"

# 1. Verify RDS read replica status
aws rds describe-db-instances \
  --db-instance-identifier $DR_DB_IDENTIFIER \
  --region $DR_REGION \
  --query 'DBInstances[0].[DBInstanceStatus,ReadReplicaSourceDBInstanceIdentifier]'

# Expected: ["available", "arn:aws:rds:us-east-1:...:db:ghost-protocol-prod-db"]

# 2. Check replication lag (should be <1 minute normally)
aws rds describe-db-instances \
  --db-instance-identifier $DR_DB_IDENTIFIER \
  --region $DR_REGION \
  --query 'DBInstances[0].StatusInfos'

# 3. Promote read replica to standalone database
aws rds promote-read-replica \
  --db-instance-identifier $DR_DB_IDENTIFIER \
  --backup-retention-period 7 \
  --region $DR_REGION

# Wait for promotion (10-20 minutes)
aws rds wait db-instance-available \
  --db-instance-identifier $DR_DB_IDENTIFIER \
  --region $DR_REGION

echo "Database promoted successfully"

# 4. Get new database endpoint
DR_DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier $DR_DB_IDENTIFIER \
  --region $DR_REGION \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "New database endpoint: $DR_DB_ENDPOINT"
```

**Verification:**
```bash
# Test database connection
PGPASSWORD=$DB_PASSWORD psql \
  -h $DR_DB_ENDPOINT \
  -U ghostadmin \
  -d postgres \
  -c "SELECT COUNT(*) FROM users;"

# Expected: Row count matching last known production count
```

### Phase A.3: Activate DR EKS Cluster (30-45 minutes)

```bash
# 1. Configure kubectl for DR cluster
aws eks update-kubeconfig \
  --name ghost-protocol-dr-cluster \
  --region $DR_REGION

# Verify cluster access
kubectl get nodes
# Expected: 2-3 nodes in Ready state

# 2. Update database connection in Kubernetes secrets
kubectl create secret generic database-credentials \
  --from-literal=DATABASE_URL="postgresql://ghostadmin:${DB_PASSWORD}@${DR_DB_ENDPOINT}:5432/postgres" \
  --dry-run=client -o yaml | kubectl apply -n ghost-protocol-prod -f -

# 3. Deploy application services
kubectl apply -k infra/k8s/overlays/production

# Wait for deployments to be ready
kubectl rollout status deployment/api-gateway -n ghost-protocol-prod
kubectl rollout status deployment/indexer -n ghost-protocol-prod
kubectl rollout status deployment/rpc-orchestrator -n ghost-protocol-prod

# 4. Verify pod health
kubectl get pods -n ghost-protocol-prod
# Expected: All pods in Running state

# 5. Test application health
kubectl port-forward -n ghost-protocol-prod svc/api-gateway 8080:3000 &
curl -f http://localhost:8080/health
# Expected: {"status":"ok"}
```

### Phase A.4: Failover DNS to DR Region (10-15 minutes)

**Critical:** This step makes the DR region live for users

```bash
# 1. Update Route53 DNS records to point to DR region
export DR_ALB_DNS=$(kubectl get ingress api-gateway-ingress -n ghost-protocol-prod \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "DR ALB DNS: $DR_ALB_DNS"

# 2. Update Route53 A record for api.ghost-protocol.io
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://<(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "api.ghost-protocol.io",
      "Type": "CNAME",
      "TTL": 60,
      "ResourceRecords": [{"Value": "$DR_ALB_DNS"}]
    }
  }]
}
EOF
)

# 3. Update Route53 for web frontend
# Point to DR CloudFront distribution
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://<(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "ghost-protocol.io",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z2FDTNDATAQYW2",
        "DNSName": "dr-frontend.cloudfront.net",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
EOF
)

# 4. Verify DNS propagation (takes 1-5 minutes)
watch -n 10 'dig api.ghost-protocol.io +short'
# Expected: DR ALB DNS name (after 1-5 minutes)
```

**Alternative: Failover via Route53 Health Check (Automatic)**

If Route53 health checks are configured:
```bash
# Health checks will automatically failover DNS to DR region
# No manual action needed if health check detects primary region failure

# Verify health check status
aws route53 get-health-check-status --health-check-id hc-xxx --region us-east-1
```

### Phase A.5: Sync S3 Data from Cross-Region Replication (10-20 minutes)

```bash
# 1. Verify S3 cross-region replication status
aws s3api get-bucket-replication \
  --bucket ghost-protocol-prod-data \
  --region us-east-1
# Note: This may fail if us-east-1 is down, proceed to DR bucket

# 2. Check DR bucket for replicated data
aws s3 ls s3://ghost-protocol-dr-data/ --recursive --region $DR_REGION

# 3. Update application to use DR S3 bucket
kubectl set env deployment/api-gateway \
  S3_BUCKET=ghost-protocol-dr-data \
  S3_REGION=$DR_REGION \
  -n ghost-protocol-prod

# Restart pods to pick up new environment
kubectl rollout restart deployment/api-gateway -n ghost-protocol-prod

# 4. Verify S3 access from application
kubectl logs -n ghost-protocol-prod -l app=api-gateway --tail=50 | grep -i s3
# Expected: No S3 errors
```

### Phase A.6: Verify Full System Operation (15-30 minutes)

**Comprehensive validation checklist:**

```bash
# 1. Cluster health
kubectl get nodes -o wide
kubectl get pods -A
# Expected: All nodes Ready, all pods Running

# 2. Database connectivity
kubectl exec -it $(kubectl get pod -n ghost-protocol-prod -l app=api-gateway -o jsonpath='{.items[0].metadata.name}') \
  -n ghost-protocol-prod -- \
  psql $DATABASE_URL -c "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';"
# Expected: Active database connections

# 3. API health
curl -f https://api.ghost-protocol.io/health
# Expected: {"status":"ok"}

# 4. End-to-end functionality test
curl https://api.ghost-protocol.io/api/v1/users/me \
  -H "Authorization: Bearer <test-token>"
# Expected: User data returned

# 5. Frontend accessibility
curl -I https://ghost-protocol.io/
# Expected: 200 OK

# 6. Transaction processing test
# Submit test transaction through API
# Verify it's indexed and appears in blockchain indexer

# 7. Monitor error rates (Grafana in DR region)
# https://grafana-dr.ghost-protocol.io/d/api-overview
# Expected: Error rate <1%
```

**Validation Checklist:**
- [ ] All pods running in DR cluster
- [ ] Database accessible and accepting connections
- [ ] S3 buckets accessible from application
- [ ] API health check returning 200 OK
- [ ] Frontend loading correctly
- [ ] User authentication working
- [ ] Transaction processing functional
- [ ] Monitoring dashboards showing healthy metrics
- [ ] DNS resolving to DR region
- [ ] No critical errors in logs

### Phase A.7: Declare Service Restored

**When to declare restored:**
- All validation checks pass
- Service has been stable for 30+ minutes
- Error rate <1%
- User reports confirm functionality

**Restoration Announcement:**

```markdown
✅ DISASTER RECOVERY COMPLETE - Service Restored

**Status:** OPERATIONAL (DR Region)
**Time:** 2025-11-16 17:30 UTC
**Total Downtime:** 3 hours 30 minutes (14:00 - 17:30 UTC)

**Summary:**
- AWS us-east-1 region failure detected at 14:00 UTC
- Disaster recovery plan activated
- Failed over to us-west-2 (DR region)
- Database promoted, services redeployed, DNS updated

**Current State:**
- Running in us-west-2 (DR region)
- All services operational
- Data loss: None (database replication caught up)
- Monitoring: Active

**Next Steps:**
- Monitor DR region for 24 hours
- Await AWS us-east-1 region restoration
- Plan failback to primary region when us-east-1 available
- Post-mortem scheduled: 2025-11-17 10:00 AM

**Incident Commander:** John Doe
Thank you for your patience during this unprecedented event.
```

## SCENARIO B: Data Recovery from Backups (Ransomware/Data Loss)

**Use when:** Database or S3 data encrypted, corrupted, or deleted

**RTO:** 4-8 hours  
**RPO:** Up to 24 hours

### Phase B.1: Isolate and Assess Damage (< 15 minutes)

```bash
# 1. IMMEDIATELY stop all write operations
kubectl scale deployment api-gateway --replicas=0 -n ghost-protocol-prod
kubectl scale deployment indexer --replicas=0 -n ghost-protocol-prod

# 2. Verify what's affected
# Database check
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U ghostadmin -d postgres \
  -c "SELECT COUNT(*) FROM users;"
# If error or unexpected count → Database compromised

# S3 check
aws s3 ls s3://ghost-protocol-prod-data/
# If empty or unexpected files → S3 compromised

# 3. Create forensic snapshots (for investigation)
# RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier ghost-protocol-prod-db \
  --db-snapshot-identifier forensic-$(date +%Y%m%d-%H%M%S) \
  --region us-east-1

# S3 bucket versioning check
aws s3api list-object-versions --bucket ghost-protocol-prod-data | head -50
```

### Phase B.2: Identify Last Known Good Backup

```bash
# 1. List RDS automated snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier ghost-protocol-prod-db \
  --snapshot-type automated \
  --region us-east-1 \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]' \
  --output table

# 2. List S3 backups (pg_dump)
aws s3 ls s3://ghost-protocol-prod-backups/database/postgresql/ \
  --recursive --human-readable

# 3. Check S3 cross-region replica (if primary compromised)
aws s3 ls s3://ghost-protocol-dr-backups/database/postgresql/ \
  --recursive --human-readable --region us-west-2

# 4. Determine restore point
# - When was ransomware/corruption detected?
# - Last known good backup BEFORE that time
# - Accept data loss from [backup time] to [incident time]

export RESTORE_SNAPSHOT="rds:ghost-protocol-prod-db-2025-11-15-04-00"
export DATA_LOSS_HOURS=16  # Hours of data lost
```

### Phase B.3: Restore Database

**Follow database-restore.md runbook for detailed steps**

```bash
# Quick reference:
# 1. Create new RDS instance from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ghost-protocol-prod-db-restored \
  --db-snapshot-identifier $RESTORE_SNAPSHOT \
  --region us-east-1

# 2. Wait for restoration (20-40 minutes)
# 3. Validate data integrity
# 4. Cutover application to restored database
```

### Phase B.4: Restore S3 Data

```bash
# Option A: Restore from versioned S3 bucket
# If S3 versioning enabled, restore deleted objects

# List deleted objects
aws s3api list-object-versions \
  --bucket ghost-protocol-prod-data \
  --query 'DeleteMarkers[?IsLatest==`true`].[Key,VersionId]' \
  --output text

# Restore deleted objects (remove delete markers)
aws s3api list-object-versions \
  --bucket ghost-protocol-prod-data \
  --query 'DeleteMarkers[?IsLatest==`true`].[Key,VersionId]' \
  --output text | while read key version_id; do
    aws s3api delete-object \
      --bucket ghost-protocol-prod-data \
      --key "$key" \
      --version-id "$version_id"
  done

# Option B: Restore from cross-region replica
aws s3 sync s3://ghost-protocol-dr-data/ s3://ghost-protocol-prod-data/ \
  --region us-west-2 --source-region us-west-2
```

### Phase B.5: Security Hardening Before Restart

```bash
# 1. Rotate ALL credentials
# - Database passwords
# - AWS access keys
# - API keys
# - JWT secrets

# 2. Update security groups (block unauthorized access)
# 3. Enable CloudTrail for forensics
# 4. Enable GuardDuty for threat detection
# 5. Review IAM permissions (principle of least privilege)

# 6. Deploy with new credentials
kubectl create secret generic database-credentials \
  --from-literal=DATABASE_URL="postgresql://ghostadmin:NEW_PASSWORD@endpoint:5432/db" \
  --dry-run=client -o yaml | kubectl apply -n ghost-protocol-prod -f -
```

### Phase B.6: Restart Services and Monitor

```bash
# 1. Scale services back up
kubectl scale deployment api-gateway --replicas=3 -n ghost-protocol-prod
kubectl scale deployment indexer --replicas=2 -n ghost-protocol-prod

# 2. Monitor for suspicious activity
# - Watch CloudWatch logs for anomalies
# - Monitor API access patterns
# - Check for unauthorized database queries

# 3. Run security audit
# - Review all IAM role usage
# - Check for new or modified resources
# - Scan for malware/backdoors in code
```

## SCENARIO C: Security Incident Recovery (AWS Account Compromised)

**Use when:** Unauthorized access to AWS account detected

**RTO:** 8-24 hours (includes forensics)  
**RPO:** Variable

### Phase C.1: Immediate Containment (< 30 minutes)

```bash
# 1. Contact AWS Support IMMEDIATELY
# Enterprise Support: 1-877-742-2121
# Report: "Security incident - AWS account compromised"

# 2. Disable compromised IAM users/roles
aws iam list-users --output table
# Identify suspicious users

# Disable access keys for ALL users (nuclear option)
aws iam list-users --query 'Users[*].UserName' --output text | while read user; do
  aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[*].AccessKeyId' --output text | while read key; do
    aws iam update-access-key --user-name $user --access-key-id $key --status Inactive
  done
done

# 3. Terminate suspicious EC2 instances
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId,LaunchTime,Tags]' \
  --output table

# Terminate unknown instances (CAREFUL!)
aws ec2 terminate-instances --instance-ids i-xxxxxxxx

# 4. Revoke temporary security credentials
# Use AWS STS to revoke sessions
```

### Phase C.2: Forensic Investigation (1-4 hours)

**Engage security team and potentially external forensics firm**

```bash
# 1. Preserve CloudTrail logs
aws s3 sync s3://ghost-protocol-cloudtrail-logs/ /forensics/cloudtrail/

# 2. Export CloudWatch logs
aws logs filter-log-events \
  --log-group-name /aws/eks/ghost-protocol-prod/cluster \
  --start-time $(date -d '24 hours ago' +%s)000 \
  --output json > /forensics/eks-logs.json

# 3. Review unauthorized actions
aws cloudtrail lookup-events \
  --start-time $(date -d '7 days ago' -u +%Y-%m-%dT%H:%M:%S) \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateUser \
  --region us-east-1

# 4. Identify data exfiltration
# Look for unusual S3 downloads, database queries, etc.
```

### Phase C.3: Rebuild Infrastructure (4-8 hours)

```bash
# 1. Deploy to DR account (clean environment)
export AWS_PROFILE=dr-account
export AWS_REGION=us-west-2

# 2. Use Terraform to rebuild infrastructure
cd infra/terraform
terraform init
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -auto-approve

# 3. Restore data from known-good backups (before breach)
# Use SCENARIO B procedures

# 4. Deploy applications with new credentials
# All secrets rotated, new API keys generated

# 5. Update DNS to point to new infrastructure
# Follow Phase A.4 procedures
```

## SCENARIO D: Infrastructure Rebuild (Terraform State Corrupted)

**Use when:** Infrastructure broken but data intact

**RTO:** 2-6 hours  
**RPO:** None (no data loss)

### Phase D.1: Terraform State Recovery

```bash
# 1. Attempt to restore Terraform state from backup
# Terraform Cloud automatically backs up state

# Download latest working state
terraform state pull > terraform.tfstate.backup

# 2. If state is corrupted, import existing resources
terraform import module.compute.aws_eks_cluster.main ghost-protocol-prod

# 3. Rebuild state file by importing all resources
# This is tedious but possible for all AWS resources

# 4. Alternatively, use AWS Resource Groups to inventory resources
aws resource-groups list-groups
```

### Phase D.2: Infrastructure Drift Correction

```bash
# 1. Run terraform plan to see drift
terraform plan -var-file=environments/prod/terraform.tfvars

# 2. Manually fix drift by updating Terraform code or AWS resources

# 3. Re-apply Terraform
terraform apply -var-file=environments/prod/terraform.tfvars
```

## Post-Disaster Activities

### Failback to Primary Region (When us-east-1 Restored)

**Timing:** After primary region stable for 24+ hours

```bash
# 1. Verify primary region health
aws ec2 describe-regions --region us-east-1

# 2. Create new RDS instance in primary region
# Replicate from DR database

# 3. Sync S3 data back to primary region
aws s3 sync s3://ghost-protocol-dr-data/ s3://ghost-protocol-prod-data/ \
  --source-region us-west-2 --region us-east-1

# 4. Rebuild EKS cluster in primary region (via Terraform)
# 5. Cutover DNS back to primary region
# 6. Decommission DR resources (keep replicas active)
```

### Post-Mortem and Lessons Learned

**Required within 48 hours of recovery:**

```markdown
# Disaster Recovery Post-Mortem

## Timeline
- Disaster detected: [Time]
- DR declared: [Time]
- Database promoted: [Time]
- Services restored: [Time]
- Total downtime: [Duration]

## What Went Well
- [List successes]

## What Went Wrong
- [List challenges]

## Action Items
- [Improvements to DR plan]
- [Infrastructure changes]
- [Documentation updates]

## Testing
- Schedule next DR drill: [Date]
```

### Update Documentation

```bash
# 1. Update runbooks with lessons learned
# 2. Document any manual steps that should be automated
# 3. Update disaster recovery contact list
# 4. Review and update RTO/RPO targets based on actual performance
```

## Disaster Recovery Testing

### Quarterly DR Drill (Required)

**Scheduled:** First Saturday of each quarter, 2:00 AM UTC  
**Duration:** 4-6 hours  
**Impact:** Staging environment only (no production impact)

```bash
# DR Drill Checklist:
# [ ] Test database failover (promote DR replica)
# [ ] Test EKS cluster deployment in DR region
# [ ] Test DNS failover
# [ ] Test application functionality in DR region
# [ ] Time each step (compare to RTO/RPO targets)
# [ ] Document issues and improvements
# [ ] Debrief with team within 1 week
```

**Drill Scenarios:**
- **Q1:** Regional failover (simulate us-east-1 failure)
- **Q2:** Data restoration (restore from old backup)
- **Q3:** Security incident (rebuild in clean account)
- **Q4:** Full end-to-end DR (combine all scenarios)

## Continuous Improvement

### Monthly Reviews

- Review DR contact list (update phone numbers, roles)
- Test DR database replica lag (<5 minutes)
- Verify S3 cross-region replication (check sync status)
- Review backup retention (ensure backups available)
- Test AWS account access (ensure credentials work)

### Annual Updates

- Re-evaluate RTO/RPO targets (based on business needs)
- Update disaster recovery budget
- Review insurance coverage (cyber insurance, business interruption)
- Conduct tabletop exercise with leadership
- Audit compliance (SOC 2, ISO 27001 DR requirements)

## References

- **AWS Disaster Recovery:** https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/
- **RTO/RPO Calculation:** https://aws.amazon.com/blogs/mt/establishing-rpo-and-rto-targets-for-cloud-applications/
- **Terraform State Management:** https://www.terraform.io/docs/language/state/index.html
- **Database Restore Runbook:** `infra/runbooks/database-restore.md`
- **Incident Response Runbook:** `infra/runbooks/incident-response.md`

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-16 | DevOps Team | Initial version |

