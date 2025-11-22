# Production Incident Response Procedure

## Overview

This runbook defines the standardized process for responding to production incidents in the Ghost Protocol infrastructure.

**Severity:** Critical  
**Estimated Time:** Varies by incident severity (15 minutes - 24+ hours)  
**Last Updated:** 2025-11-16

## Incident Classification

### P0 - Critical (Severity: Critical)

**Definition:** Complete service outage or critical security breach

**Characteristics:**
- Complete API/website unavailability (100% error rate)
- Complete database unavailability
- Data breach or unauthorized access detected
- Ransomware or critical security vulnerability exploited
- Financial loss or regulatory compliance violation in progress

**Response Time:** Immediate (< 5 minutes)  
**Notification:** Page on-call engineer immediately, notify CTO and management  
**Escalation:** Auto-escalate after 15 minutes if no response  
**SLA Impact:** Critical breach

**Examples:**
- All users cannot access the platform (502/503 errors)
- Database is down or inaccessible
- Customer data leaked or compromised
- Smart contracts hacked or funds stolen
- Complete AWS region failure

### P1 - High (Severity: High)

**Definition:** Major service degradation affecting >50% of users

**Characteristics:**
- Partial service outage (>50% users affected)
- Significant performance degradation (>2x normal latency)
- Critical feature unavailable (login, transactions, payments)
- Failed deployment affecting production
- Data inconsistency affecting multiple users

**Response Time:** < 15 minutes  
**Notification:** Alert on-call engineer via PagerDuty  
**Escalation:** Escalate after 1 hour if not resolved  
**SLA Impact:** Major breach

**Examples:**
- Login system down (users can't authenticate)
- Transaction processing failing (>50% failure rate)
- Blockchain indexer stopped (data not syncing)
- API response time >5 seconds (normally <500ms)
- Database replica lag >15 minutes

### P2 - Medium (Severity: Medium)

**Definition:** Minor service degradation affecting <50% of users

**Characteristics:**
- Partial feature degradation (<50% users affected)
- Moderate performance issues (1.5x normal latency)
- Non-critical feature unavailable
- Development/staging environment issues blocking releases
- Elevated error rates but service functional

**Response Time:** < 1 hour  
**Notification:** Create ticket, notify on-call engineer  
**Escalation:** Review in daily standup if not resolved in 4 hours  
**SLA Impact:** Minor (within acceptable limits)

**Examples:**
- Search functionality slow but working
- Admin dashboard showing stale data
- Monitoring alerts for non-critical services
- Staging environment database connection issues
- Email notifications delayed

### P3 - Low (Severity: Low)

**Definition:** Cosmetic issues or minor bugs with workarounds

**Characteristics:**
- UI/UX bugs (cosmetic, not blocking functionality)
- Documentation issues
- Non-urgent feature requests
- Minor performance optimizations needed
- Low-priority technical debt

**Response Time:** < 24 hours  
**Notification:** Create ticket in backlog  
**Escalation:** Prioritize in sprint planning  
**SLA Impact:** None

**Examples:**
- Typo in error message
- Dashboard chart not displaying correctly
- Documentation outdated
- Log message formatting issues

## Incident Response Workflow

```
Incident Detected
    │
    ├─ PHASE 1: Initial Response (< 5 minutes)
    │   ├─ Acknowledge incident
    │   ├─ Classify severity (P0/P1/P2/P3)
    │   ├─ Create incident channel
    │   └─ Notify stakeholders
    │
    ├─ PHASE 2: Investigation (5-30 minutes)
    │   ├─ Gather logs and metrics
    │   ├─ Identify affected systems
    │   ├─ Determine root cause
    │   └─ Assess impact scope
    │
    ├─ PHASE 3: Mitigation (Immediate)
    │   ├─ Implement immediate fix
    │   ├─ OR: Rollback deployment
    │   ├─ OR: Failover to backup
    │   └─ Monitor for improvement
    │
    ├─ PHASE 4: Resolution (Ongoing)
    │   ├─ Verify fix effectiveness
    │   ├─ Monitor key metrics
    │   ├─ Communicate resolution
    │   └─ Close incident
    │
    └─ PHASE 5: Post-Mortem (24-48 hours later)
        ├─ Root cause analysis
        ├─ Timeline reconstruction
        ├─ Action items
        └─ Runbook updates
```

## Phase 1: Initial Response (< 5 minutes)

### Step 1.1: Acknowledge Incident

**If alerted via PagerDuty:**
```bash
# Acknowledge in PagerDuty app or via phone
# This stops escalation timer and notifies team
```

**If detected manually:**
```bash
# Create incident in PagerDuty manually
# Title: "[P0] API Gateway complete outage"
# Severity: Critical/High/Medium/Low
# Service: ghost-protocol-production
```

### Step 1.2: Create Incident Channel

**In Slack:**
```
1. Create dedicated channel: #incident-2025-11-16-api-outage
2. Pin incident details to channel:

🚨 INCIDENT: API Gateway Outage
Severity: P0 (Critical)
Start Time: 2025-11-16 14:32 UTC
Incident Commander: @john.doe
Status: INVESTIGATING

Symptoms:
- API returning 502 errors
- All users affected
- Started ~5 minutes ago

DO NOT discuss in general channels. All incident communication in this channel.
```

### Step 1.3: Classify Severity

Use the classification matrix above to determine P0/P1/P2/P3.

**Key Questions:**
- How many users are affected? (% of total)
- Is the service completely down or degraded?
- Is there a security implication?
- Is there financial impact?
- What is the business impact?

### Step 1.4: Notify Stakeholders

**For P0 (Critical):**
```bash
# Immediate notifications (via PagerDuty, Slack, phone)
- Primary on-call engineer (auto-paged)
- Secondary on-call engineer (auto-paged after 5 min)
- Engineering Manager
- CTO
- Customer Support lead
- Post in #incidents channel

# Optional for prolonged outages (>30 min):
- CEO
- COO
- Legal (if security breach)
```

**For P1 (High):**
```bash
# Notifications (via PagerDuty, Slack)
- Primary on-call engineer (paged)
- Engineering Manager (Slack notification)
- Post in #incidents channel

# After 1 hour if not resolved:
- Escalate to CTO
```

**For P2/P3:**
```bash
# Notifications (Slack only)
- Post in #engineering channel
- Create JIRA ticket
- Assign to on-call engineer
```

### Step 1.5: Initial Status Update Template

```markdown
🚨 INCIDENT UPDATE #1 - 2025-11-16 14:35 UTC

**Status:** INVESTIGATING
**Severity:** P0 (Critical)
**Impact:** Complete API outage, all users affected
**ETA:** Unknown (investigating)

**What we know:**
- API Gateway returning 502 Bad Gateway errors
- Started at ~14:32 UTC
- Database appears healthy
- Investigating pod/node issues

**What we're doing:**
- Checking EKS pod status
- Reviewing CloudWatch logs
- Checking recent deployments

**Next update:** 14:50 UTC (15 minutes)

Incident Commander: @john.doe
```

## Phase 2: Investigation (5-30 minutes)

### Step 2.1: Gather Initial Information

**Check Recent Changes:**
```bash
# Check recent deployments
kubectl rollout history deployment/api-gateway -n ghost-protocol-prod

# Check recent Terraform changes
cd infra/terraform
git log --since="2 hours ago" --oneline

# Check recent database migrations
kubectl logs -n ghost-protocol-prod -l app=api-gateway --tail=50 | grep migration
```

**Check Service Health:**
```bash
# Check pod status
kubectl get pods -n ghost-protocol-prod

# Check node status
kubectl get nodes

# Check service endpoints
kubectl get endpoints -n ghost-protocol-prod
```

### Step 2.2: Collect Logs

**Application Logs:**
```bash
# API Gateway logs (last 100 lines)
kubectl logs -n ghost-protocol-prod -l app=api-gateway --tail=100 --timestamps

# All services (wider view)
kubectl logs -n ghost-protocol-prod --all-containers --tail=50 --since=10m

# Save logs to file for analysis
kubectl logs -n ghost-protocol-prod -l app=api-gateway --tail=500 > /tmp/api-gateway-incident-$(date +%Y%m%d-%H%M).log
```

**Infrastructure Logs:**
```bash
# EKS control plane logs (CloudWatch)
aws logs tail /aws/eks/ghost-protocol-prod/cluster --follow --since 10m

# Load balancer logs
aws logs tail /aws/elasticloadbalancing/app/ghost-protocol-prod-alb --follow --since 10m
```

### Step 2.3: Check Metrics and Dashboards

**Grafana Dashboards:**
1. Open: https://grafana.ghost-protocol.io
2. Navigate to: "Production Overview" dashboard
3. Check:
   - Request rate (should show drop if outage)
   - Error rate (should show spike)
   - Latency (p50, p95, p99)
   - Pod CPU/memory usage
   - Database connections

**CloudWatch Metrics:**
```bash
# API Gateway error rate (last 30 minutes)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=app/ghost-protocol-prod-alb/xxxxx \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --region us-east-1
```

### Step 2.4: Identify Pattern

**Common Patterns:**

| Symptom | Likely Cause | Quick Check |
|---------|--------------|-------------|
| All pods CrashLoopBackOff | Bad deployment | `kubectl rollout history` |
| Pods Running but 502 errors | Service/Ingress misconfigured | `kubectl get svc,ingress` |
| High CPU/memory | Resource exhaustion | `kubectl top pods` |
| Database connection errors | RDS issue or connection leak | Check RDS console |
| 503 Service Unavailable | No healthy pods | `kubectl get endpoints` |
| Slow response times | Database slow query | Check RDS performance insights |

### Step 2.5: Determine Impact Scope

```bash
# How many users affected?
# Check Grafana: Active users graph
# Check application metrics: sessions count

# Which features affected?
# Test key endpoints manually:
curl -i https://api.ghost-protocol.io/health
curl -i https://api.ghost-protocol.io/api/v1/users/me -H "Authorization: Bearer <token>"
curl -i https://api.ghost-protocol.io/api/v1/transactions

# Geographic impact?
# Check CloudFront metrics by region
```

**Document in incident channel:**
```
📊 IMPACT ASSESSMENT (14:40 UTC)

Users Affected: ~15,000 (100% of active users)
Features Affected: 
  ❌ API Gateway (all endpoints)
  ✅ Website (static content still serving)
  ❌ User authentication
  ❌ Transaction processing

Geographic: Global (all regions)
Duration: 8 minutes (since 14:32 UTC)
Revenue Impact: ~$500/minute (estimated)
```

## Phase 3: Mitigation (Immediate)

### Step 3.1: Decision Tree - Mitigation Strategy

```
Root Cause Identified?
    │
    ├─ Bad Deployment
    │   └─ Action: ROLLBACK (see rollback-procedure.md)
    │
    ├─ Database Issue
    │   └─ Action: Check database-restore.md or increase capacity
    │
    ├─ Infrastructure Failure (node/pod)
    │   └─ Action: See node-recovery.md
    │
    ├─ Traffic Spike / DDoS
    │   └─ Action: Enable rate limiting, scale up
    │
    ├─ External Dependency Failure (AWS, third-party API)
    │   └─ Action: Enable degraded mode, use fallback
    │
    └─ Unknown / Still Investigating
        └─ Action: Implement temporary workaround, continue investigation
```

### Step 3.2: Common Mitigation Actions

**Quick Win #1: Restart Pods**
```bash
# If pods are in CrashLoopBackOff or degraded
kubectl rollout restart deployment/api-gateway -n ghost-protocol-prod

# Monitor restart
kubectl rollout status deployment/api-gateway -n ghost-protocol-prod
```

**Quick Win #2: Scale Up**
```bash
# If resource exhaustion suspected
kubectl scale deployment api-gateway --replicas=6 -n ghost-protocol-prod

# Or enable HPA if disabled
kubectl autoscale deployment api-gateway --min=3 --max=10 --cpu-percent=70 -n ghost-protocol-prod
```

**Quick Win #3: Rollback Deployment**
```bash
# If recent deployment is suspected cause
kubectl rollout undo deployment/api-gateway -n ghost-protocol-prod

# Verify rollback
kubectl rollout status deployment/api-gateway -n ghost-protocol-prod
```

**Quick Win #4: Increase Database Capacity**
```bash
# If database is bottleneck
aws rds modify-db-instance \
  --db-instance-identifier ghost-protocol-prod-db \
  --db-instance-class db.r5.2xlarge \
  --apply-immediately \
  --region us-east-1

# Note: This causes brief downtime during instance class change
```

**Quick Win #5: Enable Degraded Mode**
```bash
# Update ConfigMap to enable read-only mode or disable non-critical features
kubectl patch configmap api-gateway-config -n ghost-protocol-prod \
  --type merge -p '{"data":{"DEGRADED_MODE":"true","DISABLE_WRITES":"true"}}'

# Restart pods to pick up config
kubectl rollout restart deployment/api-gateway -n ghost-protocol-prod
```

### Step 3.3: Monitor Mitigation Effectiveness

```bash
# Watch error rate in real-time
watch -n 5 'curl -s https://api.ghost-protocol.io/health | jq .'

# Monitor pod status
kubectl get pods -n ghost-protocol-prod -w

# Check Grafana dashboards
# Expected: Error rate decreasing, request rate recovering
```

### Step 3.4: Communication During Mitigation

**Update every 15-30 minutes for P0/P1:**

```markdown
🔧 INCIDENT UPDATE #2 - 2025-11-16 14:50 UTC

**Status:** MITIGATING
**Severity:** P0 (Critical)
**Duration:** 18 minutes
**Impact:** 100% of users unable to access API

**Root Cause:** Identified bad deployment (v2.5.3) causing pod crashes

**Mitigation In Progress:**
- Rolled back to v2.5.2 (completed 14:48 UTC)
- Pods restarting (3/6 healthy)
- Error rate decreasing from 100% to 45%

**ETA for Resolution:** 15:00 UTC (10 minutes)

**Next update:** 15:00 UTC

Incident Commander: @john.doe
```

## Phase 4: Resolution

### Step 4.1: Verify Fix Effectiveness

**Checklist:**
- [ ] All pods are Running and Ready
- [ ] Error rate < 1% (normal baseline)
- [ ] Response time within SLA (p95 < 500ms)
- [ ] No errors in last 5 minutes of logs
- [ ] All endpoints returning 200 OK
- [ ] User reports confirm service is working
- [ ] Database connections normal
- [ ] All dependent services healthy

```bash
# Comprehensive health check
echo "=== POD STATUS ==="
kubectl get pods -n ghost-protocol-prod

echo "=== ERROR RATE (last 5 min) ==="
kubectl logs -n ghost-protocol-prod -l app=api-gateway --since=5m | grep -i error | wc -l

echo "=== API HEALTH CHECK ==="
curl -f https://api.ghost-protocol.io/health

echo "=== DATABASE CONNECTIONS ==="
kubectl exec -it $(kubectl get pod -n ghost-protocol-prod -l app=api-gateway -o jsonpath='{.items[0].metadata.name}') -n ghost-protocol-prod -- \
  psql $DATABASE_URL -c "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';"
```

### Step 4.2: Extended Monitoring Period

**For P0/P1 incidents, monitor for 30-60 minutes after resolution:**

```bash
# Set up continuous monitoring
watch -n 30 'echo "=== $(date) ==="; \
  kubectl get pods -n ghost-protocol-prod | grep api-gateway; \
  curl -s https://api.ghost-protocol.io/health | jq .'

# Monitor Grafana dashboards
# Watch for:
# - Error rate stays < 1%
# - No new pod restarts
# - Latency stable
# - No alerts firing
```

### Step 4.3: Declare Resolution

**When to declare resolved:**
- Root cause fixed (not just symptoms)
- Service operating normally for 15+ minutes (P0/P1)
- All validation checks passing
- No abnormal patterns in metrics
- Users confirming service restored

**Resolution announcement:**

```markdown
✅ INCIDENT RESOLVED - 2025-11-16 15:15 UTC

**Status:** RESOLVED
**Severity:** P0 (Critical)
**Total Duration:** 43 minutes (14:32 - 15:15 UTC)
**Impact:** 100% of users unable to access API

**Root Cause:** Deployment v2.5.3 introduced null pointer exception in authentication middleware

**Resolution:**
- Rolled back to v2.5.2 at 14:48 UTC
- All services restored by 15:00 UTC
- Extended monitoring until 15:15 UTC confirmed stability

**Impact Summary:**
- Users affected: ~15,000
- Revenue impact: ~$20,000
- Support tickets: 143
- Social media mentions: 67

**Next Steps:**
- Post-mortem scheduled: 2025-11-17 10:00 AM
- Fix for v2.5.3 bug tracked in JIRA-1234
- Deploy fix with proper testing by 2025-11-17 EOD

**Incident Commander:** @john.doe
**Responders:** @jane.smith, @bob.wilson

Thank you to everyone who helped resolve this quickly! 🙏
```

### Step 4.4: Close Incident

```bash
# In PagerDuty:
# 1. Add resolution notes (copy from Slack announcement)
# 2. Mark incident as "Resolved"
# 3. Set resolution time

# In Slack:
# 1. Post final resolution message
# 2. Archive incident channel after 7 days
# 3. Update status page (if public)
```

## Phase 5: Post-Mortem (24-48 hours after resolution)

### Step 5.1: Schedule Post-Mortem Meeting

**Attendees:**
- Incident Commander
- All incident responders
- Engineering Manager
- Product Manager (for context on user impact)
- Optional: CTO (for P0 incidents)

**Duration:** 60 minutes  
**Timing:** 24-48 hours after incident (memories are fresh but emotions have cooled)

### Step 5.2: Post-Mortem Template

```markdown
# Post-Mortem: API Gateway Outage (2025-11-16)

## Incident Summary

**Incident ID:** INC-2025-11-16-001  
**Severity:** P0 (Critical)  
**Duration:** 43 minutes (14:32 - 15:15 UTC)  
**Incident Commander:** John Doe  
**Date:** 2025-11-16

## Impact

- **Users Affected:** 15,000 (100% of active users)
- **Services Affected:** API Gateway, user authentication, transaction processing
- **Revenue Impact:** $20,000 estimated
- **Support Tickets:** 143
- **SLA Breach:** Yes (99.9% monthly uptime SLA)

## Timeline (All times UTC)

| Time | Event |
|------|-------|
| 14:25 | Deployment v2.5.3 initiated |
| 14:28 | Deployment completed, pods restarted |
| 14:32 | First PagerDuty alert: High error rate |
| 14:32 | User reports start coming in |
| 14:35 | Incident declared P0, #incident-xxx created |
| 14:38 | Investigation began, logs reviewed |
| 14:42 | Root cause identified: NPE in auth middleware |
| 14:45 | Decision made to rollback deployment |
| 14:48 | Rollback to v2.5.2 completed |
| 14:52 | Pods healthy, error rate decreasing |
| 15:00 | Service fully restored |
| 15:15 | Extended monitoring confirms stability, incident resolved |

## Root Cause

**Technical Cause:**  
Deployment v2.5.3 introduced a null pointer exception in the authentication middleware when processing JWT tokens without an `exp` (expiration) claim. The code assumed all JWTs had `exp` claims, but some legacy tokens did not.

**Code Change:**
```javascript
// Bug introduced in v2.5.3:
const expirationTime = decodedToken.exp.toISOString(); // ❌ exp can be undefined

// Should have been:
const expirationTime = decodedToken.exp ? decodedToken.exp.toISOString() : null; // ✅
```

**How It Escaped Testing:**  
- Unit tests only covered tokens WITH `exp` claims
- Staging environment had all tokens regenerated recently (all had `exp`)
- Production had legacy tokens from 3 months ago (no `exp`)

## What Went Well

✅ Fast detection (within 3 minutes of first error)  
✅ Quick incident classification and escalation  
✅ Effective communication in dedicated Slack channel  
✅ Rollback procedure worked smoothly  
✅ All runbooks followed correctly  
✅ No data loss  

## What Went Wrong

❌ Insufficient test coverage for edge cases  
❌ Staging environment not true mirror of production  
❌ Deployment didn't include canary or gradual rollout  
❌ No automated rollback on error threshold  
❌ Monitoring didn't catch issue during deployment  

## Action Items

| ID | Action | Owner | Due Date | Priority |
|----|--------|-------|----------|----------|
| AI-1 | Add test cases for legacy tokens without `exp` claim | @jane.smith | 2025-11-17 | P0 |
| AI-2 | Implement canary deployment (10% → 50% → 100%) | @bob.wilson | 2025-11-23 | P0 |
| AI-3 | Set up auto-rollback on >5% error rate | @john.doe | 2025-11-20 | P1 |
| AI-4 | Add CloudWatch alarm for error rate during deployments | @jane.smith | 2025-11-18 | P1 |
| AI-5 | Sync staging database with production monthly | @bob.wilson | 2025-11-30 | P2 |
| AI-6 | Update deployment runbook with validation steps | @john.doe | 2025-11-17 | P2 |
| AI-7 | Schedule token migration to remove legacy tokens | @jane.smith | 2025-12-15 | P3 |

## Lessons Learned

1. **Testing must mirror production data characteristics** - Staging should have similar token age distribution
2. **Gradual rollouts prevent total outages** - Canary deployments would have limited impact to 10% of users
3. **Automated rollback is essential** - Waiting for human intervention cost 16 minutes
4. **Edge cases are the real killer** - Most bugs happen with unusual data, not happy paths

## Supporting Materials

- CloudWatch logs: `s3://ghost-protocol-prod-logs/incidents/2025-11-16/`
- Grafana snapshot: https://grafana.ghost-protocol.io/snapshots/xyz
- Deployment logs: `git log v2.5.2..v2.5.3`
- Slack thread: #incident-2025-11-16-api-outage

## Sign-Off

By signing below, you acknowledge that this post-mortem is accurate and action items are assigned.

- Incident Commander: John Doe (2025-11-17)
- Engineering Manager: Alice Johnson (2025-11-17)
- CTO: Michael Chen (2025-11-17)
```

### Step 5.3: Track Action Items

```bash
# Create JIRA tickets for each action item
# Link to post-mortem document
# Set priority and due dates
# Assign owners
# Track in weekly incident review meeting
```

## Example Scenarios

### Scenario 1: Complete API Outage

**Symptoms:** All API requests return 502 Bad Gateway

**Investigation:**
```bash
kubectl get pods -n ghost-protocol-prod  # All pods CrashLoopBackOff
kubectl logs -n ghost-protocol-prod -l app=api-gateway --tail=50  # Error: Connection to database failed
```

**Root Cause:** Database credentials rotated but not updated in Kubernetes secret

**Mitigation:**
```bash
# Update database credentials
kubectl create secret generic database-credentials \
  --from-literal=DATABASE_URL="postgresql://user:newpass@endpoint:5432/db" \
  --dry-run=client -o yaml | kubectl apply -n ghost-protocol-prod -f -

kubectl rollout restart deployment/api-gateway -n ghost-protocol-prod
```

### Scenario 2: Performance Degradation

**Symptoms:** API response time >5 seconds (normally <500ms)

**Investigation:**
```bash
# Check database performance
# RDS Console → Performance Insights → Top SQL queries
# Found: Unoptimized query with full table scan on large table
```

**Root Cause:** Recent code change removed database index, causing slow queries

**Mitigation:**
```bash
# Quick fix: Add index directly on database
kubectl run psql --rm -it --restart=Never --image=postgres:14 \
  --env="DATABASE_URL=$DATABASE_URL" \
  -- psql $DATABASE_URL -c "CREATE INDEX CONCURRENTLY idx_transactions_user_id ON transactions(user_id);"

# Long-term fix: Add migration for index
```

### Scenario 3: Security Breach

**Symptoms:** Unusual API calls, unauthorized data access detected

**Investigation:**
```bash
# Check CloudWatch logs for suspicious patterns
# Found: API key leaked in GitHub, being used by unauthorized party
```

**Root Cause:** Developer accidentally committed API key to public repository

**Immediate Actions:**
```bash
# 1. Rotate compromised API key immediately
# 2. Revoke all active sessions for affected users
# 3. Enable additional authentication (MFA)
# 4. Notify legal and compliance teams
# 5. Prepare user notification

# Long-term: Implement secret scanning in CI/CD
```

## References

- **Monitoring:** https://grafana.ghost-protocol.io
- **PagerDuty:** https://ghost-protocol.pagerduty.com
- **Runbooks:** `infra/runbooks/`
- **Post-Mortem Template:** `docs/templates/postmortem-template.md`
- **Incident Response Guide:** https://response.pagerduty.com/

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-16 | DevOps Team | Initial version |

