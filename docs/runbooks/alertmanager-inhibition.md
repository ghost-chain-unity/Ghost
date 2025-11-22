# AlertManager Inhibition Rules - Operational Runbook

## Overview

AlertManager inhibition rules prevent alert storms by automatically suppressing lower-severity alerts when higher-severity alerts are firing for the same service/namespace. This reduces notification noise and helps teams focus on the root cause during incidents.

## Architecture

### Inhibition Rule Design

Our inhibition strategy follows a severity hierarchy:
```
CRITICAL (P0) → suppresses → WARNING (P2), INFO (P3)
HIGH (P1)     → suppresses → WARNING (P2), INFO (P3)
WARNING (P2)  → suppresses → INFO (P3)
```

### Key Principles

1. **Equal Label Matching**: Inhibition only applies when alerts share the same:
   - `alertname` (same type of alert)
   - `service` (same service/component)
   - `namespace` (same environment)

2. **Severity Hierarchy**: Higher severity always suppresses lower severity
   - P0 (critical) > P1 (high) > P2 (warning) > P3 (info)

3. **Different Services**: Alerts for different services are never inhibited
   - Example: `DatabaseDown (postgresql)` does NOT suppress `APISlowResponse (api-gateway)`

## Current Inhibition Rules

### Rule 1: Critical → Warning
```yaml
source_match:
  severity: 'critical'
target_match:
  severity: 'warning'
equal: ['alertname', 'service', 'namespace']
```

**Example Scenario:**
- `DatabaseDown (critical)` fires for PostgreSQL
- `DatabaseSlowQueries (warning)` is inhibited
- **Why:** Database being down is root cause; slow queries are symptom

### Rule 2: Critical → Info
```yaml
source_match:
  severity: 'critical'
target_match:
  severity: 'info'
equal: ['alertname', 'service', 'namespace']
```

**Example Scenario:**
- `APIGatewayDown (critical)` fires
- `APIGatewayHighLatency (info)` is inhibited
- **Why:** Gateway being down causes high latency; no need for duplicate alerts

### Rule 3: High → Warning
```yaml
source_match:
  severity: 'high'
target_match:
  severity: 'warning'
equal: ['alertname', 'service', 'namespace']
```

**Example Scenario:**
- `PodCrashLooping (high)` fires for Indexer
- `PodRestartCount (warning)` is inhibited
- **Why:** Crash loop is root cause; restart count is symptom

### Rule 4: High → Info
```yaml
source_match:
  severity: 'high'
target_match:
  severity: 'info'
equal: ['alertname', 'service', 'namespace']
```

**Example Scenario:**
- `PodCrashLooping (high)` fires
- `PodMemoryUsage (info)` is inhibited
- **Why:** Focus on crash loop; memory info can be investigated later

### Rule 5: Warning → Info
```yaml
source_match:
  severity: 'warning'
target_match:
  severity: 'info'
equal: ['alertname', 'service', 'namespace']
```

**Example Scenario:**
- `DiskSpaceWarning (warning)` fires
- `DiskIOInfo (info)` is inhibited
- **Why:** Disk space warning is more urgent than I/O info

## Operational Procedures

### Verifying Inhibition Rules

1. **Check AlertManager Configuration**
   ```bash
   kubectl get configmap alertmanager-config -n ghost-protocol-monitoring -o yaml
   ```

2. **View Active Inhibitions**
   ```bash
   # Port-forward to AlertManager
   kubectl port-forward -n ghost-protocol-monitoring svc/alertmanager 9093:9093
   
   # Check inhibited alerts via API
   curl http://localhost:9093/api/v2/alerts | jq '.[] | select(.status.inhibitedBy != null)'
   ```

3. **AlertManager UI**
   - Navigate to: http://alertmanager.ghost-protocol.com/
   - Look for "Inhibited" badge on alerts
   - Check "Status" → "Inhibitions" to see active rules

### Testing Inhibition Behavior

Run regression tests to validate inhibition rules:

```bash
cd tests/alertmanager
chmod +x run-inhibition-tests.sh
./run-inhibition-tests.sh all
```

**Test Coverage:**
- Test Case 1: Critical suppresses Warning
- Test Case 2: Critical suppresses Info
- Test Case 3: High suppresses Warning and Info
- Test Case 4: Warning suppresses Info
- Test Case 5: No inhibition for different services

### Troubleshooting

#### Problem: Expected Inhibition Not Working

**Symptoms:**
- Lower-severity alert fires despite higher-severity alert active
- Both alerts reach receivers

**Diagnosis:**
1. Check if alerts have matching labels:
   ```bash
   curl http://localhost:9093/api/v2/alerts | jq '.[] | {alertname, severity, service, namespace}'
   ```

2. Verify `alertname`, `service`, `namespace` are identical
   - **Different values** = no inhibition (expected behavior)

3. Check AlertManager logs:
   ```bash
   kubectl logs -n ghost-protocol-monitoring deployment/alertmanager --tail=100
   ```

**Resolution:**
- If labels don't match, this is expected behavior (different services/namespaces)
- If labels match but inhibition doesn't work, check ConfigMap syntax
- Restart AlertManager after configuration changes:
  ```bash
  kubectl rollout restart deployment/alertmanager -n ghost-protocol-monitoring
  ```

#### Problem: Too Much Inhibition (Valid Alerts Suppressed)

**Symptoms:**
- Important alerts not reaching receivers
- Inhibition too aggressive

**Diagnosis:**
1. Review inhibited alerts:
   ```bash
   curl http://localhost:9093/api/v2/alerts | jq '.[] | select(.status.inhibitedBy != null) | {alertname, severity, inhibitedBy}'
   ```

2. Check if inhibition is correct based on rules

**Resolution:**
- If inhibition is correct, this is working as designed (focus on higher-severity)
- If inhibition is incorrect, review alert labels or adjust severity levels
- Consider creating separate alert rules for different contexts

#### Problem: Alert Storm Despite Inhibition

**Symptoms:**
- Multiple alerts firing for same service
- Notification flood

**Possible Causes:**
1. **Different Namespaces**: Alerts from dev/staging/prod are not inhibited (intentional)
2. **Different Services**: Each service gets its own alerts (intentional)
3. **Flapping Alerts**: Alerts firing/resolving rapidly

**Resolution:**
1. For flapping alerts, adjust `group_wait` and `group_interval`:
   ```yaml
   route:
     group_wait: 30s      # Wait before sending first notification
     group_interval: 5m   # Wait before sending batch of new alerts
     repeat_interval: 4h  # Wait before re-sending same alert
   ```

2. For multi-service outages, use broader inhibition:
   ```yaml
   # Example: Suppress all if cluster-wide issue
   - source_match:
       alertname: 'ClusterDown'
     target_match_re:
       alertname: '.*'
     equal: ['namespace']
   ```

## Monitoring and Metrics

### Key Metrics

1. **Inhibited Alerts Count**
   ```promql
   count(ALERTS{inhibited="true"})
   ```

2. **Active vs Inhibited Ratio**
   ```promql
   count(ALERTS{inhibited="true"}) / count(ALERTS)
   ```

3. **Inhibition Rule Effectiveness**
   ```promql
   # Should be close to 0 (all expected inhibitions working)
   count(ALERTS{severity="warning", inhibited="false"}) 
   and 
   count(ALERTS{severity="critical", inhibited="false"}) > 0
   ```

### Dashboards

**Grafana Dashboard:** "AlertManager Inhibition Overview"
- Panel 1: Active vs Inhibited alerts (pie chart)
- Panel 2: Inhibition by severity (bar chart)
- Panel 3: Top inhibited alerts (table)
- Panel 4: Inhibition rule effectiveness (time series)

## Best Practices

### DO ✅

1. **Use consistent labels** across all alerts
   - Always include: `alertname`, `severity`, `service`, `namespace`

2. **Test inhibition rules** after any configuration changes
   ```bash
   ./run-inhibition-tests.sh all
   ```

3. **Document alert severity** in Prometheus alert definitions
   ```yaml
   labels:
     severity: critical  # P0 - immediate action required
   ```

4. **Monitor inhibited alerts** to ensure important signals aren't lost
   - Review weekly: "What alerts are being inhibited?"
   - Validate: "Is this inhibition correct?"

5. **Group related alerts** to maximize inhibition benefits
   ```yaml
   route:
     group_by: ['alertname', 'severity', 'service']
   ```

### DON'T ❌

1. **Don't over-inhibit** - Balance noise reduction with visibility
   - Example: Don't inhibit ALL alerts based on single critical

2. **Don't use inhibition as alert fix** - Fix flapping/noisy alerts at source
   - Bad: Inhibit `HighMemoryUsage` because it fires too often
   - Good: Adjust `HighMemoryUsage` threshold or evaluation window

3. **Don't forget cross-namespace** - Different environments should have separate alerts
   - `prod` database down should NOT suppress `dev` database alerts

4. **Don't skip testing** - Always validate after configuration changes
   - Broken inhibition = either alert storm OR missed critical alerts

## Change Management

### Adding New Inhibition Rules

1. **Identify need**: What alerts are causing noise?
2. **Design rule**: Define source/target match + equal labels
3. **Test rule**: Use test framework before production
4. **Document**: Update this runbook with new rule
5. **Deploy**: Apply ConfigMap changes
6. **Monitor**: Verify rule effectiveness in production

### Removing Inhibition Rules

1. **Justify removal**: Why is inhibition no longer needed?
2. **Impact assessment**: What alerts will now fire?
3. **Notify team**: Warn about increased notification volume
4. **Deploy gradually**: Test in dev/staging first
5. **Monitor**: Watch for alert storms

## Related Documentation

- [AlertManager Configuration](../adr/ADR-monitoring-stack.md)
- [Prometheus Alerts](../../infra/k8s/base/monitoring/prometheus-alerts.yaml)
- [On-Call Runbooks](./on-call-procedures.md)
- [Incident Response](./incident-response.md)

## Contacts

- **AlertManager Issues**: #infrastructure-alerts
- **On-Call Engineer**: See PagerDuty schedule
- **Escalation**: Platform Engineering Lead

---

**Last Updated:** 2025-11-16  
**Maintained By:** Platform Engineering Team  
**Review Cycle:** Quarterly
