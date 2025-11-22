# Loki HA Operations Runbook - Ghost Protocol

## Overview

This runbook covers operational procedures for Loki High Availability deployment in Simple Scalable Deployment (SSD) mode with S3 backend. The system consists of three main components: Write Path (ingestion), Read Path (queries), and Backend (maintenance).

**Architecture:** Simple Scalable Deployment (3 targets)
**Storage:** AWS S3 (ghost-protocol-prod-loki-chunks)
**Replication:** 3x replication for data durability
**Namespace:** ghost-protocol-monitoring

**Related Documentation:**
- [Loki HA Architecture](../architecture/loki-ha-architecture.md)
- [Monitoring Stack Overview](./monitoring-stack.md)
- [AlertManager Inhibition](./alertmanager-inhibition.md)

---

## Table of Contents

1. [Deployment Procedures](#deployment-procedures)
2. [Migration from Monolithic](#migration-from-monolithic)
3. [Operations](#operations)
4. [Troubleshooting](#troubleshooting)
5. [Monitoring and Alerts](#monitoring-and-alerts)
6. [Disaster Recovery](#disaster-recovery)
7. [Performance Tuning](#performance-tuning)

---

## Deployment Procedures

### Initial Deployment

**Prerequisites:**
1. ✅ Terraform applied (S3 buckets + IAM role created)
2. ✅ EKS cluster running with sufficient capacity
3. ✅ Monitoring namespace exists
4. ✅ Storage class `gp3` available

**Step 1: Update ServiceAccount with IAM Role ARN**

```bash
# Get IAM role ARN from Terraform output
cd infra/terraform/environments/production
terraform output loki_irsa_role_arn

# Update ServiceAccount annotation
kubectl edit serviceaccount loki -n ghost-protocol-monitoring

# Add annotation:
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ghost-protocol-prod-loki-irsa-role
```

**Step 2: Deploy Loki HA Components**

```bash
# Apply all Loki HA manifests
kubectl apply -k infra/k8s/base/monitoring/

# Verify deployments
kubectl get pods -n ghost-protocol-monitoring -l app=loki

# Expected output:
# loki-write-0     1/1  Running
# loki-write-1     1/1  Running
# loki-write-2     1/1  Running
# loki-read-0      1/1  Running
# loki-read-1      1/1  Running
# loki-read-2      1/1  Running
# loki-backend-0   1/1  Running
# loki-gateway-xxx 1/1  Running (2 replicas)
```

**Step 3: Verify Memberlist Ring**

```bash
# Check memberlist members (should see all 7 pods)
kubectl logs -n ghost-protocol-monitoring loki-write-0 | grep memberlist

# Example output:
# level=info msg="joining memberlist cluster" members=7
```

**Step 4: Verify S3 Connectivity**

```bash
# Check S3 writes (should see successful uploads)
kubectl logs -n ghost-protocol-monitoring loki-write-0 | grep -i s3

# Example output:
# level=info msg="uploaded chunk" bucket=ghost-protocol-prod-loki-chunks
```

**Step 5: Verify Data Ingestion**

```bash
# Send test log
kubectl run test-logger --image=busybox --restart=Never -- sh -c 'for i in $(seq 1 10); do echo "test log $i"; sleep 1; done'

# Check Loki for test logs (via Grafana or LogCLI)
# Should see logs appear within 5-10 seconds
```

### Rollout Updates

**Zero-Downtime Update Strategy:**

```bash
# Update ConfigMap (example: change retention period)
kubectl edit configmap loki-write-config -n ghost-protocol-monitoring

# Rolling restart write path (one pod at a time)
kubectl rollout restart statefulset loki-write -n ghost-protocol-monitoring

# Watch rollout
kubectl rollout status statefulset loki-write -n ghost-protocol-monitoring

# Verify no data loss (check memberlist still has 3 write replicas)
kubectl logs -n ghost-protocol-monitoring loki-write-0 | grep "ring members"
```

**Image Upgrade:**

```bash
# Edit StatefulSet to change image version
kubectl set image statefulset/loki-write loki=grafana/loki:2.9.4 -n ghost-protocol-monitoring

# Repeat for read and backend
kubectl set image statefulset/loki-read loki=grafana/loki:2.9.4 -n ghost-protocol-monitoring
kubectl set image statefulset/loki-backend loki=grafana/loki:2.9.4 -n ghost-protocol-monitoring

# Monitor rollout
kubectl get pods -n ghost-protocol-monitoring -w
```

---

## Migration from Monolithic

### Pre-Migration Checklist

- [ ] Terraform S3 buckets created and accessible
- [ ] IAM role ARN added to ServiceAccount
- [ ] Backup of current Loki data (PVC snapshot)
- [ ] Backup of current manifests (.bak files exist)
- [ ] Maintenance window scheduled (low traffic period)
- [ ] Team notified of potential query disruption

### Migration Steps

**Phase 1: Parallel Deployment (Day 1)**

```bash
# 1. Deploy new Loki HA stack (parallel to old monolithic)
kubectl apply -k infra/k8s/base/monitoring/

# 2. Verify new stack is healthy
kubectl get pods -n ghost-protocol-monitoring -l app=loki

# 3. DO NOT delete old loki deployment yet
```

**Phase 2: Dual-Write (Day 2)**

```bash
# 1. Update Promtail to send logs to BOTH old and new Loki
kubectl edit configmap promtail-config -n ghost-protocol-monitoring

# Add second client (temporary):
clients:
  - url: http://loki:3100/loki/api/v1/push  # Old monolithic
  - url: http://loki-gateway:3100/loki/api/v1/push  # New HA

# 2. Restart Promtail
kubectl rollout restart daemonset promtail -n ghost-protocol-monitoring

# 3. Monitor ingestion on both stacks
kubectl logs -n ghost-protocol-monitoring loki-write-0 | grep ingestion_rate
kubectl logs -n ghost-protocol-monitoring loki-0 | grep ingestion_rate  # Old
```

**Phase 3: Validation (Day 3)**

```bash
# 1. Query recent logs from NEW stack (via Grafana)
# Switch Loki datasource URL to: http://loki-gateway:3100

# 2. Verify queries work
# Run test queries for last 1 hour (should see data)

# 3. Compare old vs new results
# Same query on both datasources should return identical results
```

**Phase 4: Cutover (Day 4)**

```bash
# 1. Update Promtail to ONLY send to new Loki
kubectl edit configmap promtail-config -n ghost-protocol-monitoring

# Remove old client:
clients:
  - url: http://loki-gateway:3100/loki/api/v1/push  # New HA only

# 2. Restart Promtail
kubectl rollout restart daemonset promtail -n ghost-protocol-monitoring

# 3. Update Grafana datasource
# Point to: http://loki-gateway:3100 (permanent)

# 4. Monitor for 24 hours
# Watch for errors, data gaps, query performance
```

**Phase 5: Cleanup (Day 5-7)**

```bash
# 1. Verify no issues for 24 hours
# 2. Scale down old Loki deployment
kubectl scale deployment loki --replicas=0 -n ghost-protocol-monitoring

# 3. Monitor for 48 hours (rollback still possible)

# 4. Delete old deployment (after 7 days)
kubectl delete deployment loki -n ghost-protocol-monitoring
kubectl delete service loki -n ghost-protocol-monitoring
kubectl delete configmap loki-config -n ghost-protocol-monitoring

# 5. Snapshot old PVC before deletion
# AWS Backup or manual snapshot

# 6. Delete old PVC (after 30 days)
kubectl delete pvc loki-storage-loki-0 -n ghost-protocol-monitoring
```

### Rollback Procedure

**If migration fails within 7 days:**

```bash
# 1. Revert Promtail to old Loki
kubectl edit configmap promtail-config -n ghost-protocol-monitoring
clients:
  - url: http://loki:3100/loki/api/v1/push  # Old monolithic

# 2. Scale up old Loki
kubectl scale deployment loki --replicas=1 -n ghost-protocol-monitoring

# 3. Revert Grafana datasource
# Point back to: http://loki:3100

# 4. Investigate issues with new stack
# Check logs, S3 permissions, IAM role, memberlist
```

---

## Operations

### Scaling Operations

**Scale Write Path (Ingestion)**

```bash
# Increase replicas for higher ingestion throughput
kubectl scale statefulset loki-write --replicas=5 -n ghost-protocol-monitoring

# Verify new pods join memberlist
kubectl logs -n ghost-protocol-monitoring loki-write-3 | grep "joining memberlist"

# Monitor ingestion distribution
# Check each pod's ingestion rate (should be balanced)
for i in {0..4}; do
  echo "loki-write-$i:"
  kubectl exec -n ghost-protocol-monitoring loki-write-$i -- wget -qO- http://localhost:3100/metrics | grep loki_distributor_bytes_received_total
done
```

**Scale Read Path (Queries)**

```bash
# Increase replicas for higher query load
kubectl scale statefulset loki-read --replicas=5 -n ghost-protocol-monitoring

# Update gateway to include new replicas (if static upstream)
# Most NGINX configs use Kubernetes DNS which auto-discovers new pods
```

**Scale Backend**

```bash
# Backend typically runs 1 replica
# Can scale to 3 for HA (compactor uses ring for coordination)
kubectl scale statefulset loki-backend --replicas=3 -n ghost-protocol-monitoring
```

### Data Retention Management

**Change Retention Period:**

```bash
# Edit ConfigMaps
kubectl edit configmap loki-write-config -n ghost-protocol-monitoring
kubectl edit configmap loki-read-config -n ghost-protocol-monitoring
kubectl edit configmap loki-backend-config -n ghost-protocol-monitoring

# Update:
limits_config:
  retention_period: 720h  # Change from 720h (30 days) to desired value

# Restart all components
kubectl rollout restart statefulset loki-write -n ghost-protocol-monitoring
kubectl rollout restart statefulset loki-read -n ghost-protocol-monitoring
kubectl rollout restart statefulset loki-backend -n ghost-protocol-monitoring
```

**Manual Compaction Trigger:**

```bash
# Compaction runs every 10 minutes by default
# To trigger manually, restart backend
kubectl delete pod loki-backend-0 -n ghost-protocol-monitoring

# Check compaction logs
kubectl logs -n ghost-protocol-monitoring loki-backend-0 | grep compaction
```

### S3 Bucket Management

**Check S3 Usage:**

```bash
# Get bucket size
aws s3 ls s3://ghost-protocol-prod-loki-chunks --recursive --summarize | grep "Total Size"

# Get object count
aws s3 ls s3://ghost-protocol-prod-loki-chunks --recursive --summarize | grep "Total Objects"

# Estimate monthly cost (assuming $0.023/GB)
# Example: 10TB = 10,000 GB × $0.023 = $230/month
```

**S3 Lifecycle Policy Verification:**

```bash
# Check lifecycle rules
aws s3api get-bucket-lifecycle-configuration --bucket ghost-protocol-prod-loki-chunks

# Expected rules:
# - Transition to Intelligent-Tiering after 30 days
# - Delete after retention period (30 days)
```

**S3 Access Audit:**

```bash
# Check S3 access logs (if enabled)
aws s3 ls s3://ghost-protocol-prod-logs/s3-access-logs/loki_chunks/

# Check for failed requests
aws s3 sync s3://ghost-protocol-prod-logs/s3-access-logs/loki_chunks/ . --exclude "*" --include "*$(date +%Y-%m-%d)*"
grep "HTTP/1.1\" 4" * | wc -l  # Count 4xx errors
grep "HTTP/1.1\" 5" * | wc -l  # Count 5xx errors
```

---

## Troubleshooting

### Issue: Pods Not Starting

**Symptoms:**
- Pods stuck in CrashLoopBackOff or Pending

**Diagnosis:**

```bash
# Check pod status
kubectl get pods -n ghost-protocol-monitoring -l app=loki

# Check events
kubectl describe pod loki-write-0 -n ghost-protocol-monitoring | tail -20

# Check logs
kubectl logs -n ghost-protocol-monitoring loki-write-0 --previous
```

**Common Causes:**

1. **IAM Role Not Configured:**
   ```bash
   # Error in logs: "AccessDenied: Access Denied"
   # Solution: Verify ServiceAccount annotation
   kubectl get sa loki -n ghost-protocol-monitoring -o yaml | grep role-arn
   ```

2. **S3 Bucket Not Accessible:**
   ```bash
   # Error in logs: "NoSuchBucket: The specified bucket does not exist"
   # Solution: Verify bucket exists and IAM role has permissions
   aws s3 ls s3://ghost-protocol-prod-loki-chunks
   ```

3. **PVC Not Bound:**
   ```bash
   # Pod pending with "FailedAttachVolume" or "FailedMount"
   # Solution: Check PVC status and storage class
   kubectl get pvc -n ghost-protocol-monitoring
   kubectl describe pvc loki-write-storage-loki-write-0 -n ghost-protocol-monitoring
   ```

4. **Resource Limits:**
   ```bash
   # Pod OOMKilled or CPU throttling
   # Solution: Increase resource limits
   kubectl edit statefulset loki-write -n ghost-protocol-monitoring
   ```

### Issue: Data Not Ingesting

**Symptoms:**
- Logs not appearing in Grafana
- Promtail shows errors

**Diagnosis:**

```bash
# Check Promtail logs
kubectl logs -n ghost-protocol-monitoring daemonset/promtail | grep -i error

# Check Loki write path logs
kubectl logs -n ghost-protocol-monitoring loki-write-0 | grep -i error

# Check gateway logs
kubectl logs -n ghost-protocol-monitoring deployment/loki-gateway | grep -i error
```

**Common Causes:**

1. **Gateway Misconfigured:**
   ```bash
   # Test gateway routing
   kubectl exec -n ghost-protocol-monitoring loki-write-0 -- wget -qO- http://loki-gateway:3100/ready
   
   # Should return "ready"
   # If not, check NGINX config
   kubectl get configmap loki-gateway-config -n ghost-protocol-monitoring -o yaml
   ```

2. **Promtail Not Reaching Gateway:**
   ```bash
   # Test from Promtail pod
   kubectl exec -n ghost-protocol-monitoring daemonset/promtail -- wget -qO- http://loki-gateway:3100/ready
   
   # If fails, check network policies or DNS
   kubectl get networkpolicies -n ghost-protocol-monitoring
   ```

3. **Rate Limiting:**
   ```bash
   # Error in logs: "ingestion rate limit exceeded"
   # Solution: Increase limits in ConfigMap
   limits_config:
     ingestion_rate_mb: 20  # Increase from 10
     ingestion_burst_size_mb: 40  # Increase from 20
   ```

### Issue: Queries Failing or Slow

**Symptoms:**
- Grafana queries timeout
- "context deadline exceeded" errors

**Diagnosis:**

```bash
# Check querier logs
kubectl logs -n ghost-protocol-monitoring loki-read-0 | grep -i "query"

# Check query performance metrics
kubectl exec -n ghost-protocol-monitoring loki-read-0 -- wget -qO- http://localhost:3100/metrics | grep loki_request_duration_seconds
```

**Common Causes:**

1. **S3 Latency:**
   ```bash
   # Check S3 request duration
   kubectl exec -n ghost-protocol-monitoring loki-read-0 -- wget -qO- http://localhost:3100/metrics | grep loki_s3_request_duration_seconds
   
   # High latency > 1s indicates S3 issues
   # Solution: Check AWS service health, VPC endpoints
   ```

2. **Large Query Range:**
   ```bash
   # Queries spanning >24 hours can be slow
   # Solution: Use query splitting (already enabled in query-frontend)
   # Or reduce query range in Grafana
   ```

3. **Index Cache Miss:**
   ```bash
   # Check cache hit ratio
   kubectl exec -n ghost-protocol-monitoring loki-read-0 -- wget -qO- http://localhost:3100/metrics | grep loki_cache_
   
   # Low hit ratio < 50% indicates cache issues
   # Solution: Increase cache size in ConfigMap
   ```

### Issue: Memberlist Split Brain

**Symptoms:**
- Pods not seeing each other in ring
- Duplicate data or missing logs

**Diagnosis:**

```bash
# Check memberlist members from each pod
for pod in loki-write-0 loki-write-1 loki-write-2; do
  echo "$pod memberlist:"
  kubectl logs -n ghost-protocol-monitoring $pod | grep "ring members" | tail -1
done

# All should report same member count (7 total)
```

**Solution:**

```bash
# Restart all pods to re-join memberlist
kubectl delete pod -n ghost-protocol-monitoring -l app=loki

# Verify memberlist converges
kubectl logs -n ghost-protocol-monitoring loki-write-0 | grep "ring members"
# Should see: ring members=7
```

---

## Monitoring and Alerts

### Key Metrics

**Ingestion Metrics:**
```promql
# Total ingestion rate (logs/sec)
sum(rate(loki_distributor_lines_received_total[1m]))

# Per-pod ingestion rate
rate(loki_distributor_lines_received_total[1m])

# Bytes ingested per second
rate(loki_distributor_bytes_received_total[1m])
```

**Query Metrics:**
```promql
# Query duration (P95)
histogram_quantile(0.95, rate(loki_request_duration_seconds_bucket{route="loki_api_v1_query_range"}[5m]))

# Query error rate
rate(loki_request_duration_seconds_count{status_code=~"5.."}[5m])

# Concurrent queries
loki_querier_queries_running
```

**Storage Metrics:**
```promql
# Chunks in memory (ingesters)
sum(loki_ingester_memory_chunks)

# S3 upload rate
rate(loki_boltdb_shipper_uploads_total[5m])

# S3 error rate
rate(loki_s3_request_duration_seconds_count{status_code!~"2.."}[5m])
```

**Replication Metrics:**
```promql
# Ring members (should be 7)
loki_ring_members{name="ingester"}

# Chunk replication lag
loki_ingester_flush_queue_length
```

### Prometheus Alerts

**Critical Alerts:**

```yaml
# Loki Write Path Down
- alert: LokiWritePathDown
  expr: up{job="loki-write"} == 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Loki write path is down"
    description: "No write replicas available - log ingestion stopped"

# Loki S3 Errors
- alert: LokiS3Errors
  expr: rate(loki_s3_request_duration_seconds_count{status_code!~"2.."}[5m]) > 0.1
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Loki S3 errors detected"
    description: "S3 API errors at {{ $value }}/sec - check IAM/bucket permissions"

# Loki Replication Lag
- alert: LokiReplicationLag
  expr: loki_ingester_flush_queue_length > 5000
  for: 10m
  labels:
    severity: high
  annotations:
    summary: "Loki replication lag high"
    description: "Ingester has {{ $value }} chunks pending S3 flush"
```

**Warning Alerts:**

```yaml
# Loki Query Latency High
- alert: LokiQueryLatencyHigh
  expr: histogram_quantile(0.95, rate(loki_request_duration_seconds_bucket{route="loki_api_v1_query_range"}[5m])) > 30
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Loki query latency high"
    description: "P95 query latency is {{ $value }}s (threshold: 30s)"

# Loki Ingestion Rate Drop
- alert: LokiIngestionRateDrop
  expr: rate(loki_distributor_lines_received_total[5m]) < 100
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Loki ingestion rate dropped"
    description: "Ingestion rate is {{ $value }} logs/sec (threshold: 100)"
```

### Grafana Dashboards

**Dashboard: Loki HA Overview**

Panels to create:
1. **Ingestion Rate** (time series)
   - Query: `sum(rate(loki_distributor_lines_received_total[1m]))`
   
2. **Query Performance** (gauge + time series)
   - Query: `histogram_quantile(0.95, rate(loki_request_duration_seconds_bucket[5m]))`
   
3. **Component Health** (stat panel)
   - Query: `up{job=~"loki-(write|read|backend)"}`
   
4. **S3 Operations** (time series)
   - Upload rate: `rate(loki_boltdb_shipper_uploads_total[5m])`
   - Error rate: `rate(loki_s3_request_duration_seconds_count{status_code!~"2.."}[5m])`
   
5. **Memberlist Status** (stat panel)
   - Query: `loki_ring_members`
   
6. **Storage Usage** (time series)
   - In-memory chunks: `sum(loki_ingester_memory_chunks)`
   - Flush queue: `sum(loki_ingester_flush_queue_length)`

**Import Existing Dashboards:**
- Loki Operational: https://grafana.com/grafana/dashboards/13407
- Loki Dashboard Quick Search: https://grafana.com/grafana/dashboards/12019

---

## Disaster Recovery

### Backup Strategy

**S3 Bucket Backup:**

```bash
# Enable S3 versioning (already enabled for ruler bucket)
aws s3api put-bucket-versioning \
  --bucket ghost-protocol-prod-loki-ruler \
  --versioning-configuration Status=Enabled

# Enable cross-region replication (optional)
# Create replication rule in AWS Console or Terraform
```

**PVC Snapshots:**

```bash
# Create snapshot of write path PVC (before major changes)
kubectl get pvc -n ghost-protocol-monitoring -l app.kubernetes.io/component=write

# Use AWS Backup or manual EBS snapshot
aws ec2 create-snapshot \
  --volume-id vol-xxx \
  --description "Loki write PVC backup $(date +%Y-%m-%d)"
```

**Configuration Backup:**

```bash
# Backup all ConfigMaps and manifests
kubectl get configmap -n ghost-protocol-monitoring -o yaml > loki-configmaps-backup.yaml
kubectl get statefulset -n ghost-protocol-monitoring -o yaml > loki-statefulsets-backup.yaml

# Store in version control (Git)
```

### Recovery Scenarios

**Scenario 1: Single Pod Failure**

- **Impact:** Minimal (2/3 replicas still serving)
- **Recovery:** Automatic (Kubernetes restarts pod)
- **Action:** Monitor for automatic recovery, investigate logs if repeated failures

**Scenario 2: Complete Write Path Failure**

```bash
# Symptoms: All write pods down, no logs ingesting
# Impact: Log ingestion stopped, queries still work (S3 data intact)

# Recovery:
# 1. Check recent changes (config, deployment)
kubectl describe statefulset loki-write -n ghost-protocol-monitoring

# 2. Rollback if needed
kubectl rollout undo statefulset loki-write -n ghost-protocol-monitoring

# 3. Force restart
kubectl delete pod -n ghost-protocol-monitoring -l app.kubernetes.io/component=write

# 4. Verify recovery
kubectl get pods -n ghost-protocol-monitoring -l app.kubernetes.io/component=write
```

**Scenario 3: S3 Bucket Deleted**

```bash
# Symptoms: S3 errors, queries fail for historical data
# Impact: CRITICAL - all historical data lost (unless versioned/replicated)

# Recovery:
# 1. Check S3 versioning/lifecycle (if enabled, restore from versions)
aws s3api list-object-versions --bucket ghost-protocol-prod-loki-chunks

# 2. Restore from cross-region replica (if enabled)
aws s3 sync s3://ghost-protocol-dr-loki-chunks s3://ghost-protocol-prod-loki-chunks

# 3. If no backup: Data loss - restart with fresh bucket
# Recent logs (last 12 hours) still in ingesters' memory
```

**Scenario 4: Complete Cluster Failure**

```bash
# Symptoms: EKS cluster down
# Impact: No logs ingesting or queryable
# S3 data intact (no data loss)

# Recovery:
# 1. Restore EKS cluster (from Terraform)
cd infra/terraform/environments/production
terraform apply

# 2. Redeploy Loki HA
kubectl apply -k infra/k8s/base/monitoring/

# 3. Verify S3 data accessible
kubectl logs -n ghost-protocol-monitoring loki-read-0 | grep "loaded chunk"

# Data recovery: All S3 data intact, queryable immediately after deployment
```

### RTO/RPO Targets

| Scenario | Recovery Time Objective (RTO) | Recovery Point Objective (RPO) |
|----------|------------------------------|-------------------------------|
| Single pod failure | 5 minutes (automatic) | 0 (no data loss) |
| Write path failure | 15 minutes (manual rollback) | 0 (buffered in memory) |
| Read path failure | 15 minutes (manual rollback) | N/A (queries only) |
| S3 bucket issue | 1 hour (restore/recreate) | 12 hours (in-memory buffer) |
| Complete cluster failure | 4 hours (rebuild cluster) | 12 hours (in-memory buffer) |

---

## Performance Tuning

### Ingestion Optimization

**Increase Ingestion Limits:**

```yaml
# loki-write-configmap.yaml
limits_config:
  ingestion_rate_mb: 20  # From 10
  ingestion_burst_size_mb: 40  # From 20
  per_stream_rate_limit: 10MB  # From 5MB
  per_stream_rate_limit_burst: 30MB  # From 15MB
```

**Batch Size Optimization:**

```yaml
# promtail-configmap.yaml (on log shippers)
clients:
  - url: http://loki-gateway:3100/loki/api/v1/push
    batchwait: 1s  # Max wait before sending batch
    batchsize: 1048576  # 1MB batch size (default 102400 = 100KB)
```

**Chunk Settings:**

```yaml
# loki-write-configmap.yaml
chunk_store_config:
  chunk_target_size: 1572864  # 1.5MB (default 1MB)
  chunk_encoding: snappy  # Or gzip for better compression
```

### Query Optimization

**Query Frontend Caching:**

```yaml
# loki-read-configmap.yaml
query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 500  # Increase cache size
```

**Query Splitting:**

```yaml
# loki-read-configmap.yaml
query_range:
  split_queries_by_interval: 15m  # Split large queries into 15min chunks
  parallelise_shardable_queries: true
```

**Index Cache Tuning:**

```yaml
# loki-read-configmap.yaml
storage_config:
  index_queries_cache_config:
    embedded_cache:
      enabled: true
      max_size_mb: 500
```

### Resource Optimization

**Right-Sizing Pods:**

```bash
# Check actual resource usage
kubectl top pod -n ghost-protocol-monitoring -l app=loki

# Adjust based on usage:
# - CPU: Should be <70% of limit under normal load
# - Memory: Should be <80% of limit with headroom for spikes

# Update StatefulSet resources
kubectl edit statefulset loki-write -n ghost-protocol-monitoring
```

**Storage Optimization:**

```bash
# Enable S3 Transfer Acceleration (for multi-region)
aws s3api put-bucket-accelerate-configuration \
  --bucket ghost-protocol-prod-loki-chunks \
  --accelerate-configuration Status=Enabled

# Use Intelligent-Tiering (already configured in Terraform)
# Automatically moves cold data to cheaper tiers
```

---

## Contacts

- **Loki Issues:** #infrastructure-loki (Slack)
- **On-Call Engineer:** See PagerDuty schedule
- **Platform Engineering Lead:** platform-eng-lead@ghost-protocol.com
- **Escalation:** infrastructure-escalation@ghost-protocol.com

---

**Last Updated:** 2025-11-16  
**Maintained By:** Platform Engineering Team  
**Review Cycle:** Quarterly  
**Next Review:** 2025-02-16
