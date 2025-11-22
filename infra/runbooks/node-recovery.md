# EKS Node Recovery Procedure

## Overview

This runbook provides step-by-step procedures for recovering failed or degraded Amazon EKS worker nodes in the Ghost Protocol infrastructure.

**Severity:** High  
**Estimated Time:** 15-45 minutes (depending on issue severity)  
**Last Updated:** 2025-11-16

## Symptoms

Node recovery is needed when you observe:

- **Node Status:** Node shows as `NotReady` or `Unknown`
- **Pod Evictions:** Pods are being evicted from the node
- **Resource Pressure:** High CPU (>90%), memory (>90%), or disk pressure alerts
- **Network Issues:** Node cannot communicate with API server
- **Kubelet Failures:** Kubelet service is crashing or unresponsive
- **PagerDuty Alert:** "EKS Node Health Check Failed" or "Node NotReady"

## Prerequisites

### Required Access
- AWS Console access (read/write for EC2, EKS)
- kubectl access to EKS cluster (admin permissions)
- SSH access to nodes (via AWS Systems Manager Session Manager)
- PagerDuty access (to acknowledge/resolve alerts)

### Required Tools
```bash
aws --version        # AWS CLI v2.x
kubectl version      # kubectl 1.28+
jq --version         # jq for JSON parsing
```

### Environment Setup
```bash
# Set environment variables
export AWS_REGION="us-east-1"
export CLUSTER_NAME="ghost-protocol-prod"  # or dev/staging
export ENVIRONMENT="prod"  # or dev/staging

# Configure kubectl
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

# Verify connection
kubectl get nodes
```

## Decision Tree

```
Node Issue Detected
    │
    ├─ Is node NotReady?
    │   ├─ Yes → Follow Section 1: Diagnose Node Status
    │   └─ No → Continue
    │
    ├─ Is node under resource pressure (CPU/Mem/Disk)?
    │   ├─ Yes → Follow Section 2: Resource Pressure Recovery
    │   └─ No → Continue
    │
    ├─ Is kubelet failing?
    │   ├─ Yes → Follow Section 3: Kubelet Recovery
    │   └─ No → Continue
    │
    ├─ Are pods stuck in Terminating/Pending?
    │   ├─ Yes → Follow Section 4: Pod Eviction Issues
    │   └─ No → Continue
    │
    └─ Node unreachable/network issues?
        └─ Yes → Follow Section 5: Network Troubleshooting
```

## Section 1: Diagnose Node Status

### Step 1.1: Identify Affected Node(s)

```bash
# List all nodes and their status
kubectl get nodes -o wide

# Filter NotReady nodes
kubectl get nodes | grep NotReady

# Get detailed node information
export NODE_NAME="ip-10-0-1-123.us-east-1.compute.internal"
kubectl describe node $NODE_NAME
```

**Expected Output Analysis:**
- `Conditions`: Look for `Ready=False`, `DiskPressure=True`, `MemoryPressure=True`
- `Events`: Check for recent events (node shutdown, kubelet stopped, etc.)
- `Allocated resources`: Check CPU/memory utilization

### Step 1.2: Check Node Events

```bash
# Get recent events for the node
kubectl get events --field-selector involvedObject.name=$NODE_NAME --sort-by='.lastTimestamp'

# Check for eviction events
kubectl get events -A | grep -i evict | grep $NODE_NAME
```

### Step 1.3: Check CloudWatch Metrics

```bash
# Get EC2 instance ID from node
INSTANCE_ID=$(kubectl get node $NODE_NAME -o jsonpath='{.spec.providerID}' | cut -d'/' -f5)
echo "Instance ID: $INSTANCE_ID"

# Check EC2 instance status
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --region $AWS_REGION

# View CloudWatch metrics (last 1 hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum \
  --region $AWS_REGION
```

**Verification:** 
- Instance status should show system/instance checks
- If both checks fail → Likely AWS infrastructure issue
- If only instance check fails → Node-level issue

## Section 2: Resource Pressure Recovery

### Step 2.1: Identify Resource Pressure Type

```bash
# Check node conditions
kubectl describe node $NODE_NAME | grep -A5 "Conditions:"

# Check disk usage on node
kubectl debug node/$NODE_NAME -it --image=busybox -- df -h

# Check pod resource consumption
kubectl top pods -A --sort-by=cpu | grep $NODE_NAME
kubectl top pods -A --sort-by=memory | grep $NODE_NAME
```

### Step 2.2: Decision - Clean Up or Drain?

**If Disk Pressure:**
```bash
# Connect to node via SSM
aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION

# Inside node: Clean up Docker images
sudo crictl rmi --prune

# Clean up old logs
sudo journalctl --vacuum-time=2d

# Exit session
exit

# Wait 2-3 minutes and verify
kubectl get node $NODE_NAME
```

**If CPU/Memory Pressure:**
```bash
# Identify top resource consumers
kubectl top pods -A --field-selector spec.nodeName=$NODE_NAME --sort-by=cpu

# Option A: Kill specific high-usage pod (if misbehaving)
kubectl delete pod <pod-name> -n <namespace>

# Option B: Drain entire node (safer for production)
# → Continue to Section 6: Drain and Replace Node
```

**Verification:**
```bash
# Wait 2-3 minutes for node to stabilize
kubectl get node $NODE_NAME -w

# Expected: Node returns to Ready status
# If still NotReady after 5 minutes → Proceed to drain/replace
```

## Section 3: Kubelet Recovery

### Step 3.1: Check Kubelet Status

```bash
# Connect to node
aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION

# Check kubelet status
sudo systemctl status kubelet

# Check kubelet logs (last 100 lines)
sudo journalctl -u kubelet -n 100 --no-pager

# Check for certificate issues
sudo ls -la /var/lib/kubelet/pki/
```

### Step 3.2: Restart Kubelet

```bash
# Restart kubelet service
sudo systemctl restart kubelet

# Wait 30 seconds
sleep 30

# Verify kubelet is running
sudo systemctl status kubelet

# Exit session
exit
```

### Step 3.3: Verify Recovery

```bash
# Check node status (wait 1-2 minutes)
kubectl get node $NODE_NAME -w

# Check node conditions
kubectl describe node $NODE_NAME | grep -A10 "Conditions:"
```

**Verification:**
- Kubelet should be `active (running)`
- Node should return to `Ready` status within 2 minutes
- If still failing → Check kubelet logs for certificate errors (may need to rotate certificates)

**If kubelet still failing:**
```bash
# This indicates deeper issues → Proceed to Section 6: Drain and Replace Node
```

## Section 4: Pod Eviction Issues

### Step 4.1: Identify Stuck Pods

```bash
# Find pods stuck in Terminating state
kubectl get pods -A --field-selector spec.nodeName=$NODE_NAME | grep Terminating

# Find pods stuck in Pending state
kubectl get pods -A --field-selector spec.nodeName=$NODE_NAME | grep Pending
```

### Step 4.2: Force Delete Stuck Pods

```bash
# Force delete a stuck pod (use with caution!)
kubectl delete pod <pod-name> -n <namespace> --grace-period=0 --force

# For multiple stuck pods
kubectl get pods -A --field-selector spec.nodeName=$NODE_NAME | grep Terminating | \
  awk '{print $1 " " $2}' | while read ns pod; do
    kubectl delete pod $pod -n $ns --grace-period=0 --force
  done
```

**Warning:** Force deletion should only be used when pods are stuck >10 minutes.

## Section 5: Network Troubleshooting

### Step 5.1: Check Security Groups

```bash
# Get security groups for the node
aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION \
  --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text

# Check security group rules
SG_ID="sg-xxxxxxxxx"  # Replace with actual SG ID
aws ec2 describe-security-groups --group-ids $SG_ID --region $AWS_REGION
```

**Verify:**
- Inbound: Allows kubelet port (10250) from EKS control plane security group
- Outbound: Allows all traffic (0.0.0.0/0)

### Step 5.2: Check VPC Networking

```bash
# Check node subnet
SUBNET_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION \
  --query 'Reservations[].Instances[].SubnetId' --output text)

# Verify subnet has route to NAT Gateway or Internet Gateway
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
  --region $AWS_REGION --output table
```

## Section 6: Drain and Replace Node (Nuclear Option)

**Use when:** Node cannot be recovered through other methods

**Estimated Time:** 15-30 minutes

### Step 6.1: Pre-Drain Checks

```bash
# Check how many pods are on this node
kubectl get pods -A --field-selector spec.nodeName=$NODE_NAME | wc -l

# Check if node hosts critical system pods
kubectl get pods -A --field-selector spec.nodeName=$NODE_NAME | grep -E "(kube-proxy|aws-node|ebs-csi)"

# Verify other nodes have capacity
kubectl top nodes
```

**Decision Point:**
- If <10 pods and cluster has capacity → Safe to drain
- If >50 pods or cluster near capacity → Consider gradual migration first
- If critical system pods only → May need to force drain

### Step 6.2: Cordon Node (Prevent New Pods)

```bash
# Mark node as unschedulable
kubectl cordon $NODE_NAME

# Verify node is cordoned
kubectl get node $NODE_NAME
# Expected: STATUS shows "Ready,SchedulingDisabled"
```

### Step 6.3: Drain Node

```bash
# Drain node gracefully (respects PodDisruptionBudgets)
kubectl drain $NODE_NAME \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=300s

# If drain times out or fails, force drain (use with extreme caution)
kubectl drain $NODE_NAME \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=30
```

**What this does:**
1. Evicts all pods from the node (except DaemonSets)
2. Waits for pods to terminate gracefully (respects terminationGracePeriodSeconds)
3. Deletes emptyDir volumes (data will be lost)

### Step 6.4: Terminate EC2 Instance

```bash
# Verify node is fully drained
kubectl get pods -A --field-selector spec.nodeName=$NODE_NAME
# Expected: Only DaemonSet pods (kube-proxy, aws-node, ebs-csi-node)

# Terminate the instance (Auto Scaling will launch replacement)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION

# Monitor termination
aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION \
  --query 'Reservations[].Instances[].State.Name' --output text
```

### Step 6.5: Verify Replacement Node

```bash
# Watch for new node to join (takes 3-5 minutes)
kubectl get nodes -w

# Expected: New node with name like "ip-10-0-1-234.us-east-1.compute.internal"

# Verify new node is Ready
export NEW_NODE_NAME="ip-10-0-1-234.us-east-1.compute.internal"
kubectl get node $NEW_NODE_NAME

# Verify pods are rescheduled
kubectl get pods -A -o wide | grep $NEW_NODE_NAME
```

### Step 6.6: Clean Up Old Node (If Stuck in NotReady)

```bash
# If old node is stuck in NotReady for >10 minutes after termination
kubectl delete node $NODE_NAME

# Verify deletion
kubectl get nodes | grep $NODE_NAME
# Expected: No results
```

**Verification Checklist:**
- [ ] New node is in `Ready` status
- [ ] All pods have been rescheduled successfully
- [ ] No pods stuck in `Pending` state
- [ ] Cluster autoscaler is functioning (if enabled)
- [ ] Application endpoints are healthy

## Section 7: Post-Recovery Validation

### Step 7.1: Verify Cluster Health

```bash
# Check all nodes are Ready
kubectl get nodes

# Check pod distribution
kubectl get pods -A -o wide --sort-by=.spec.nodeName

# Verify no pending pods
kubectl get pods -A | grep Pending
```

### Step 7.2: Verify Application Health

```bash
# Check API Gateway health
kubectl get pods -n ghost-protocol-prod -l app=api-gateway

# Test API endpoint
curl -f https://api.ghost-protocol.io/health || echo "API health check failed"

# Check service endpoints
kubectl get endpoints -n ghost-protocol-prod
```

### Step 7.3: Check Monitoring Dashboards

1. **Grafana:** https://grafana.ghost-protocol.io
   - Navigate to "EKS Cluster Overview" dashboard
   - Verify all nodes show green status
   - Check for any spike in pod restarts

2. **CloudWatch:**
   - Navigate to EKS → Clusters → ghost-protocol-prod → Workloads
   - Verify no pods in CrashLoopBackOff or Error state

3. **PagerDuty:**
   - Resolve the incident with resolution notes
   - Document actions taken

## Preventive Measures

### 1. Enable Cluster Autoscaler Logs

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler --tail=100
```

### 2. Set Up Pod Disruption Budgets (PDB)

```yaml
# Example PDB for API Gateway
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-gateway-pdb
  namespace: ghost-protocol-prod
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api-gateway
```

### 3. Monitor Node Health Metrics

```bash
# Create CloudWatch alarm for node NotReady events
aws cloudwatch put-metric-alarm \
  --alarm-name eks-node-not-ready-$ENVIRONMENT \
  --alarm-description "Alert when EKS node becomes NotReady" \
  --metric-name cluster_failed_node_count \
  --namespace ContainerInsights \
  --statistic Average \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### 4. Regular Node Rotation (Proactive)

```bash
# Rotate nodes monthly to prevent long-running issues
# This is automated in production via Terraform node group refresh
```

## Troubleshooting Common Issues

### Issue: Drain Command Hangs

**Symptom:** `kubectl drain` command runs for >10 minutes without completing

**Cause:** Pods have long termination grace periods or PodDisruptionBudget is blocking

**Solution:**
```bash
# Check which pods are blocking
kubectl get pods -A --field-selector spec.nodeName=$NODE_NAME -o json | \
  jq '.items[] | select(.metadata.deletionTimestamp != null) | {name: .metadata.name, namespace: .metadata.namespace, grace: .spec.terminationGracePeriodSeconds}'

# Force drain with shorter grace period
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data --force --grace-period=30
```

### Issue: Replacement Node Not Joining Cluster

**Symptom:** After terminating node, no replacement node appears within 10 minutes

**Cause:** Auto Scaling Group configuration issue or AWS service limits

**Solution:**
```bash
# Check Auto Scaling Group
ASG_NAME=$(aws autoscaling describe-auto-scaling-instances \
  --instance-ids $INSTANCE_ID --region $AWS_REGION \
  --query 'AutoScalingInstances[0].AutoScalingGroupName' --output text)

# Verify ASG desired capacity
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME \
  --region $AWS_REGION --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize]'

# Check ASG activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name $ASG_NAME \
  --max-records 10 --region $AWS_REGION

# If needed, manually set desired capacity
aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME \
  --desired-capacity <current+1> --region $AWS_REGION
```

### Issue: Pods Stuck in Pending After Node Replacement

**Symptom:** Pods remain in `Pending` state after new node joins

**Cause:** Insufficient resources, taints/tolerations mismatch, or PVC binding issues

**Solution:**
```bash
# Check pod events
kubectl describe pod <pending-pod-name> -n <namespace>

# Common causes in Events section:
# - "Insufficient cpu/memory" → Need larger node or reduce requests
# - "node(s) had taint..." → Check node taints vs pod tolerations
# - "persistentvolumeclaim not found" → PVC/PV issues

# Check node capacity
kubectl describe node $NEW_NODE_NAME | grep -A5 "Allocated resources"

# If taints issue, remove taint
kubectl taint nodes $NEW_NODE_NAME <taint-key>-
```

## Escalation Path

If node recovery fails after following this runbook:

1. **Check #incidents Slack channel** - See if others are experiencing similar issues
2. **Review AWS Service Health Dashboard** - Check for regional EC2/EKS issues
3. **Escalate to Senior SRE** - If multiple nodes failing simultaneously
4. **Contact AWS Support** - If AWS infrastructure issue suspected (Enterprise Support: 1-877-742-2121)

## References

- **Monitoring Dashboards:**
  - Grafana: https://grafana.ghost-protocol.io/d/eks-nodes
  - CloudWatch: AWS Console → CloudWatch → Container Insights → ghost-protocol-prod
  
- **Terraform Modules:**
  - EKS Cluster: `infra/terraform/modules/compute/aws/main.tf`
  - Node Groups: `infra/terraform/modules/compute/aws/node_groups.tf`
  
- **Kubernetes Manifests:**
  - Monitoring: `infra/k8s/base/monitoring/`
  
- **External Resources:**
  - [EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
  - [Kubernetes Node Pressure](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/)

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-16 | DevOps Team | Initial version |

