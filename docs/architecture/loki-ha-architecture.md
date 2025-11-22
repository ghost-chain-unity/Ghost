# Loki High Availability Architecture - Ghost Protocol

## Executive Summary

This document outlines the migration of Loki from a single-replica, filesystem-based deployment to a highly available, distributed architecture with S3 object storage backend. This is a **prerequisite** for ArgoCD GitOps rollout (Phase 0.4.8) per architect guidance.

**Current State:** ❌ Not Production-Ready
- Single replica (no failover)
- Filesystem storage (not scalable)
- In-memory kvstore (no distributed coordination)

**Target State:** ✅ Production-Ready
- 3 replicas minimum (HA with automatic failover)
- S3 object storage (scalable, durable, 99.999999999% durability)
- Memberlist kvstore (distributed service discovery)
- Simple Scalable Deployment mode (recommended for ~few TB/day)

## Architecture Decision

### Deployment Mode: Simple Scalable Deployment (SSD)

**Why SSD over Microservices?**
- ✅ **Balance:** Best balance between simplicity and scalability
- ✅ **Proven:** Default in Grafana Loki Helm chart
- ✅ **Scalable:** Handles up to several TB/day (sufficient for Ghost Protocol)
- ✅ **Maintainable:** Fewer moving parts than full microservices (9 components → 3 targets)
- ✅ **Cost-Effective:** Fewer pods = lower compute costs

**Comparison:**

| Deployment Mode | Components | Daily Volume | Complexity | Recommendation |
|----------------|-----------|--------------|------------|----------------|
| Monolithic | All-in-one | ~100GB/day | Low | ❌ Not HA |
| **Simple Scalable (SSD)** | **3 targets** | **~Few TB/day** | **Medium** | **✅ SELECTED** |
| Microservices | 9 separate | >TB/day | High | ⚠️ Overkill |

## Component Architecture

### SSD Components (3 Targets)

#### 1. **Write Path** (Distributor + Ingester)
- **Replicas:** 3 (HA)
- **Responsibilities:**
  - Receive incoming log streams
  - Validate and hash streams
  - Buffer logs in memory
  - Persist chunks to S3
- **Scaling:** Based on ingestion throughput
- **Storage:** 10Gi persistent volume (buffer before S3 flush)

#### 2. **Read Path** (Querier + Query Frontend + Ruler)
- **Replicas:** 3 (HA)
- **Responsibilities:**
  - Execute LogQL queries
  - Query in-memory data from write path
  - Query historical data from S3
  - Split large queries for optimization
  - Cache query results
- **Scaling:** Based on query load
- **Storage:** 10Gi persistent volume (cache)

#### 3. **Backend** (Compactor + Index Gateway + Query Scheduler)
- **Replicas:** 1-3 (typically 1, with HA capability)
- **Responsibilities:**
  - Compact index files (96+ → 1 per day)
  - Manage data retention
  - Serve index queries
  - Schedule queries across queriers
- **Scaling:** Usually single instance
- **Storage:** 10Gi persistent volume (compaction workspace)

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         WRITE PATH                               │
├─────────────────────────────────────────────────────────────────┤
│  Promtail/Agent                                                  │
│       │                                                          │
│       ▼                                                          │
│  Distributor (validates, hashes)                                │
│       │                                                          │
│       ▼                                                          │
│  Ingester (buffers, replicates 3x)                              │
│       │                                                          │
│       ▼                                                          │
│  S3 Bucket (chunks + indexes)                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         READ PATH                                │
├─────────────────────────────────────────────────────────────────┤
│  Grafana                                                         │
│       │                                                          │
│       ▼                                                          │
│  Query Frontend (splits, caches)                                │
│       │                                                          │
│       ▼                                                          │
│  Query Scheduler (load balances)                                │
│       │                                                          │
│       ▼                                                          │
│  Querier ───► Ingesters (in-memory, recent logs)                │
│       └─────► S3 Bucket (historical logs)                       │
│       │                                                          │
│       ▼                                                          │
│  Grafana (merged results)                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      MAINTENANCE PATH                            │
├─────────────────────────────────────────────────────────────────┤
│  Compactor (every 10 minutes)                                   │
│       │                                                          │
│       ▼                                                          │
│  S3 Bucket (read indexes, compact, write back)                  │
│       │                                                          │
│       └─────► Retention cleanup (30-day policy)                 │
└─────────────────────────────────────────────────────────────────┘
```

## Storage Backend: S3 Object Storage

### S3 Bucket Design

**Bucket 1: `ghost-protocol-loki-chunks-prod`**
- **Purpose:** Store compressed log chunks
- **Lifecycle Policy:**
  - 30 days: Standard (hot data)
  - 31-90 days: S3 Intelligent-Tiering (warm data)
  - 91+ days: Delete (or Glacier for compliance)
- **Versioning:** Disabled (chunks are immutable)
- **Encryption:** SSE-S3 (server-side encryption)

**Bucket 2: `ghost-protocol-loki-ruler-prod`** (optional)
- **Purpose:** Store alerting/recording rules
- **Lifecycle Policy:** No expiration
- **Versioning:** Enabled (track rule changes)
- **Encryption:** SSE-S3

### S3 Benefits

| Benefit | Impact |
|---------|--------|
| **Durability** | 99.999999999% (11 nines) - data never lost |
| **Availability** | 99.99% SLA - multi-AZ automatic replication |
| **Scalability** | Unlimited capacity - no disk full scenarios |
| **Cost** | Pay-per-use - $0.023/GB/month Standard tier |
| **Performance** | 3,500 PUT/s, 5,500 GET/s per prefix |
| **Disaster Recovery** | Cross-region replication ready |

## Configuration Changes

### Migration Summary

| Configuration | Current (Monolithic) | Target (SSD + S3) |
|--------------|---------------------|------------------|
| **Deployment Mode** | All-in-one | Simple Scalable |
| **Replicas** | 1 | Write: 3, Read: 3, Backend: 1 |
| **Replication Factor** | 1 | 3 |
| **Object Store** | filesystem | s3 |
| **Schema Store** | boltdb-shipper | tsdb (TSDB) |
| **Schema Version** | v11 | v13 (latest 2024) |
| **Kvstore** | inmemory | memberlist |
| **Storage Class** | gp3 (10Gi per pod) | gp3 (10Gi) + S3 |

### Critical Configuration Updates

#### 1. Storage Backend (S3)
```yaml
storage_config:
  aws:
    s3: s3://ghost-protocol-loki-chunks-prod
    region: us-east-1
    sse_encryption: true
    s3forcepathstyle: false
  
  tsdb_shipper:
    active_index_directory: /loki/tsdb-index
    cache_location: /loki/tsdb-cache
    cache_ttl: 24h
    shared_store: s3
```

#### 2. Schema (TSDB + v13)
```yaml
schema_config:
  configs:
    - from: 2024-11-16  # Migration date
      store: tsdb        # Time-series database (vs boltdb-shipper)
      object_store: s3
      schema: v13        # Latest schema (better performance)
      index:
        prefix: loki_index_
        period: 24h
```

#### 3. Replication & HA
```yaml
common:
  replication_factor: 3  # 3 replicas for HA
  ring:
    kvstore:
      store: memberlist  # Distributed service discovery
    replication_factor: 3
```

#### 4. Memberlist (Service Discovery)
```yaml
memberlist:
  node_name: ${HOSTNAME}
  bind_port: 7946
  join_members:
    # DNS-based discovery for write/read/backend pods
    - loki-write-headless.ghost-protocol-monitoring.svc.cluster.local:7946
    - loki-read-headless.ghost-protocol-monitoring.svc.cluster.local:7946
    - loki-backend-headless.ghost-protocol-monitoring.svc.cluster.local:7946
```

## Kubernetes Manifests

### Deployment Strategy

**Before:** 1 StatefulSet (loki)
**After:** 3 StatefulSets + Services

```
loki-write (StatefulSet, 3 replicas)
├── loki-write-headless (Service, ClusterIP: None)
└── loki-write (Service, ClusterIP)

loki-read (StatefulSet, 3 replicas)
├── loki-read-headless (Service, ClusterIP: None)
└── loki-read (Service, ClusterIP)

loki-backend (StatefulSet, 1 replica)
├── loki-backend-headless (Service, ClusterIP: None)
└── loki-backend (Service, ClusterIP)

loki-gateway (Deployment, 2 replicas)
└── loki-gateway (Service, ClusterIP) → routes to write/read/backend
```

### Resource Allocation

**Write Path (per replica):**
```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi
```

**Read Path (per replica):**
```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi
```

**Backend (per replica):**
```yaml
resources:
  requests:
    cpu: 200m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### Anti-Affinity (HA)

Ensure pods spread across nodes:
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/component
                operator: In
                values:
                  - write  # or read, backend
          topologyKey: kubernetes.io/hostname
```

## AWS Infrastructure (Terraform)

### IAM Role for Service Account (IRSA)

**Service Account:** `loki` (namespace: `ghost-protocol-monitoring`)

**IAM Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::ghost-protocol-loki-chunks-prod",
        "arn:aws:s3:::ghost-protocol-loki-chunks-prod/*",
        "arn:aws:s3:::ghost-protocol-loki-ruler-prod",
        "arn:aws:s3:::ghost-protocol-loki-ruler-prod/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    }
  ]
}
```

**Trust Relationship:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID:sub": "system:serviceaccount:ghost-protocol-monitoring:loki"
        }
      }
    }
  ]
}
```

### Terraform Modules

**New Resources:**
1. `aws_s3_bucket.loki_chunks`
2. `aws_s3_bucket.loki_ruler`
3. `aws_s3_bucket_lifecycle_configuration.loki_chunks_lifecycle`
4. `aws_s3_bucket_encryption.loki_chunks_encryption`
5. `aws_iam_role.loki_irsa`
6. `aws_iam_policy.loki_s3_access`
7. `aws_iam_role_policy_attachment.loki_s3_attachment`

**Module Location:** `infra/terraform/modules/observability/aws/`

## Migration Plan

### Phase 1: Terraform Infrastructure (Day 1)
1. Create S3 buckets with lifecycle policies
2. Create IAM role with S3 permissions
3. Configure IRSA for `loki` ServiceAccount
4. Validate access with test pod

### Phase 2: Kubernetes Manifests (Day 2-3)
1. Create new ConfigMaps (write/read/backend configs)
2. Create ServiceAccounts with IAM annotations
3. Deploy StatefulSets (write, read, backend)
4. Deploy Services (headless + ClusterIP)
5. Deploy Gateway (NGINX) for routing
6. Update Promtail to point to new gateway

### Phase 3: Data Migration (Day 4)
1. Deploy new Loki stack (parallel to old)
2. Dual-write: Promtail → old + new Loki
3. Validate data ingestion in new stack
4. Verify queries work across both stacks
5. Cutover: Grafana → new Loki only

### Phase 4: Cleanup (Day 5)
1. Stop old Loki deployment
2. Delete old PVCs (after backup)
3. Update monitoring dashboards
4. Document migration in runbooks

### Rollback Plan
- Keep old deployment for 7 days
- Grafana can switch back to old Loki datasource
- PVCs retained for 30 days (snapshot before deletion)

## High Availability Features

### Automatic Failover
- **Write Path:** 3 replicas with replication_factor=3
  - If 1 ingester fails → 2 replicas still have data
  - Minimum quorum: 2/3 (can tolerate 1 failure)
- **Read Path:** 3 replicas
  - If 1 querier fails → 2 queriers still serve requests
  - Load balancer distributes load round-robin
- **Backend:** 1 replica (non-critical path)
  - Compaction can pause temporarily without data loss
  - Can scale to 3 replicas if needed

### Data Durability
- **S3 Backend:** 99.999999999% durability (11 nines)
- **Multi-AZ Replication:** Automatic cross-AZ replication
- **Chunk Replication:** 3x replication in ingesters before S3 flush
- **No Single Point of Failure:** All components horizontally scaled

### Performance Characteristics

**Expected Performance:**
- **Ingestion:** 50,000 logs/sec (distributed across 3 write replicas)
- **Query Latency:** <1s for recent logs, <5s for 30-day range
- **Retention:** 30 days (configurable via limits_config)
- **Storage Cost:** ~$0.023/GB/month (S3 Standard)

## Monitoring & Alerting

### Key Metrics

**Loki Health:**
- `loki_ingester_flush_queue_length` - Backlog before S3 flush
- `loki_request_duration_seconds` - Query performance
- `loki_ingester_memory_chunks` - In-memory chunks count
- `loki_boltdb_shipper_uploads_total` - S3 upload rate

**S3 Operations:**
- `loki_s3_request_duration_seconds` - S3 API latency
- `loki_chunk_store_stored_chunks_total` - Chunks stored in S3

**Replication:**
- `loki_ingester_sent_chunks` - Cross-replica chunk replication
- `loki_ring_members` - Memberlist health

### Prometheus Alerts

**New Alerts:**
```yaml
- alert: LokiWritePathDown
  expr: up{job="loki-write"} == 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Loki write path is down"
    description: "No write replicas available - log ingestion stopped"

- alert: LokiReplicationLag
  expr: loki_ingester_flush_queue_length > 1000
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Loki replication lag high"
    description: "Ingester has {{ $value }} chunks pending S3 flush"

- alert: LokiS3Errors
  expr: rate(loki_s3_request_duration_seconds_count{status_code!~"2.."}[5m]) > 0.1
  for: 5m
  labels:
    severity: high
  annotations:
    summary: "Loki S3 errors detected"
    description: "S3 API errors at {{ $value }}/sec - check IAM/bucket permissions"
```

## Security Considerations

### IAM Least Privilege
- ✅ Only S3 permissions (no EC2, no other services)
- ✅ Scoped to specific buckets (no wildcard buckets)
- ✅ IRSA instead of access keys (no credentials in pods)

### Data Encryption
- ✅ S3 Server-Side Encryption (SSE-S3)
- ✅ TLS in-transit (HTTPS for S3 API calls)
- ✅ Network policies for pod-to-pod communication

### Audit Logging
- ✅ S3 access logging to separate audit bucket
- ✅ CloudTrail for S3 API calls
- ✅ Kubernetes audit logs for pod operations

## Cost Analysis

### Infrastructure Costs (Monthly)

**Compute (EKS):**
- Write: 3 pods × 1 vCPU × $0.05/hr = $108/month
- Read: 3 pods × 1 vCPU × $0.05/hr = $108/month
- Backend: 1 pod × 0.5 vCPU × $0.05/hr = $18/month
- **Total Compute:** ~$234/month

**Storage (S3):**
- Assuming 1TB ingestion/day, 30-day retention
- 30TB × $0.023/GB = $690/month (Standard)
- With lifecycle to Intelligent-Tiering: ~$400/month
- **Total Storage:** ~$400-690/month

**EBS (Persistent Volumes):**
- 7 pods × 10Gi × $0.10/GB = $7/month
- **Total EBS:** ~$7/month

**Total Monthly Cost:** ~$641-931/month (vs ~$50/month for monolithic filesystem)

**Cost Optimization:**
- Use S3 Intelligent-Tiering (saves ~40%)
- Reduce retention to 14 days (saves 50% storage)
- Use Spot instances for read path (saves 70% compute)

## Success Criteria

### Technical Acceptance
- ✅ All 3 targets deployed with green health
- ✅ 3 replicas for write/read paths running
- ✅ Memberlist shows all pods in ring
- ✅ Logs successfully ingested to S3
- ✅ Queries return results from S3 and in-memory
- ✅ No data loss during 1-pod failure test
- ✅ Compaction running every 10 minutes

### Operational Acceptance
- ✅ Grafana dashboards show all metrics
- ✅ Prometheus alerts firing correctly
- ✅ Runbooks updated with HA procedures
- ✅ Team trained on new architecture
- ✅ Incident response tested (simulate pod failure)

## References

### External Documentation
- [Grafana Loki Deployment Modes](https://grafana.com/docs/loki/latest/get-started/deployment-modes/)
- [Loki S3 Storage Guide](https://last9.io/blog/loki-s3-storage-guide/)
- [InfraCloud HA Guide](https://www.infracloud.io/blogs/high-availability-disaster-recovery-in-loki/)
- [AWS EKS + Loki Guide](https://medium.com/@CloudifyOps/a-comprehensive-guide-to-setting-up-loki-in-a-distributed-manner-on-amazon-eks-part-1-f9a732857d41)

### Internal Documentation
- [ADR-005: Infrastructure Deployment Strategy](../adr/ADR-20251115-005-infrastructure-deployment-strategy.md)
- [Roadmap Tasks 0.4.8-0.4.10](../../roadmap-tasks.md)
- [Monitoring Stack Overview](../runbooks/monitoring-stack.md)

---

**Document Status:** ✅ APPROVED  
**Author:** Platform Engineering Team  
**Created:** 2025-11-16  
**Last Updated:** 2025-11-16  
**Review Cycle:** Quarterly  
**Next Review:** 2025-02-16
