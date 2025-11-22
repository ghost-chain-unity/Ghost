# Production Overlay - Loki HA with Terraform Integration

## Overview

This production overlay applies environment-specific configurations to Loki HA, including S3 bucket names, AWS region, and IRSA role ARN from Terraform outputs.

## Prerequisites

1. **Terraform Applied:**
   ```bash
   cd infra/terraform/environments/production
   terraform init
   terraform plan
   terraform apply
   ```

2. **Terraform Outputs Available:**
   ```bash
   terraform output loki_chunks_bucket_name
   terraform output loki_ruler_bucket_name
   terraform output loki_irsa_role_arn
   terraform output -raw aws_region
   ```

## Deployment Steps

**IMPORTANT:** Always use the automated script `update-loki-terraform-outputs.sh` to ensure patches are up-to-date with Terraform outputs. Manual editing is error-prone and not recommended.

### Step 1: Run Automated Update Script (Recommended)

The automated script `update-loki-terraform-outputs.sh` fetches Terraform outputs and updates Kustomize patches automatically:

```bash
cd infra/k8s/overlays/production

# Run the update script
./update-loki-terraform-outputs.sh
```

**Expected Output:**
```
🔍 Fetching Terraform outputs from: ../../../terraform/environments/production
📥 Retrieving Terraform outputs...
✅ Retrieved Terraform outputs:
   Chunks Bucket: ghost-protocol-prod-loki-chunks
   Ruler Bucket: ghost-protocol-prod-loki-ruler
   AWS Region: us-east-1
   IRSA ARN: arn:aws:iam::123456789012:role/ghost-protocol-prod-loki-irsa-role
💾 Creating backups...
🔧 Updating loki-config-patch.yaml...
🔧 Updating loki-sa-patch.yaml...
✅ Patches updated successfully!
✅ No placeholders detected in patches
```

### Step 2: Verify Patches Updated

Check that Terraform outputs were injected correctly:

```bash
cd infra/k8s/overlays/production

# Verify S3 bucket names
grep -A1 "s3:" loki-config-patch.yaml | head -5

# Expected: s3://ghost-protocol-prod-loki-chunks (actual bucket name)
# NOT: s3://ghost-protocol-prod-loki-chunks (placeholder)

# Verify IRSA ARN
grep "role-arn:" loki-sa-patch.yaml

# Expected: arn:aws:iam::123456789012:role/ghost-protocol-prod-loki-irsa-role
# NOT: arn:aws:iam::ACCOUNT_ID:role/...

# Check for remaining placeholders
grep -iE "ACCOUNT_ID|PLACEHOLDER|TODO" loki-config-patch.yaml loki-sa-patch.yaml || echo "✅ No placeholders found"
```

### Step 3: Validate Kustomization

```bash
cd infra/k8s/overlays/production

# Build kustomization (dry-run)
kubectl kustomize . > /tmp/loki-ha-production.yaml

# Verify S3 bucket names and IRSA ARN are correct
grep -A2 "s3:" /tmp/loki-ha-production.yaml
grep "role-arn" /tmp/loki-ha-production.yaml

# Check for any remaining placeholders
grep -E "ACCOUNT_ID|PLACEHOLDER|TODO" /tmp/loki-ha-production.yaml || echo "✅ No placeholders found"
```

### Step 4: Apply to Cluster

**Dry Run First:**
```bash
kubectl apply -k infra/k8s/overlays/production --dry-run=server
```

**Apply:**
```bash
kubectl apply -k infra/k8s/overlays/production
```

**Verify Deployment:**
```bash
# Check pods
kubectl get pods -n ghost-protocol-prod -l app=loki

# Expected:
# loki-write-0     1/1  Running
# loki-write-1     1/1  Running
# loki-write-2     1/1  Running
# loki-read-0      1/1  Running
# loki-read-1      1/1  Running
# loki-read-2      1/1  Running
# loki-backend-0   1/1  Running
# loki-gateway-xxx 1/1  Running (2 replicas)

# Check ServiceAccount has IRSA annotation
kubectl get sa loki -n ghost-protocol-prod -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'

# Expected: arn:aws:iam::123456789012:role/ghost-protocol-prod-loki-irsa-role

# Check S3 connectivity (wait 30s for pods to start)
kubectl logs -n ghost-protocol-prod loki-write-0 | grep -i s3 | grep -i "uploaded\|success"

# Expected: Successfully uploaded chunks to S3
```

## Troubleshooting

### Issue: Pods CrashLoopBackOff

**Check Logs:**
```bash
kubectl logs -n ghost-protocol-prod loki-write-0
```

**Common Errors:**

1. **NoSuchBucket:**
   ```
   Error: NoSuchBucket: The specified bucket does not exist
   ```
   - **Cause:** Bucket name mismatch or Terraform not applied
   - **Solution:** Verify bucket exists in AWS Console or reapply Terraform
     ```bash
     aws s3 ls s3://ghost-protocol-prod-loki-chunks
     ```

2. **AccessDenied:**
   ```
   Error: AccessDenied: User: arn:aws:sts::xxx is not authorized
   ```
   - **Cause:** IRSA role ARN incorrect or IAM policy insufficient
   - **Solution:** Verify ServiceAccount annotation
     ```bash
     kubectl describe sa loki -n ghost-protocol-prod
     ```

3. **InvalidBucketName:**
   ```
   Error: InvalidBucketName: The specified bucket is not valid
   ```
   - **Cause:** Bucket name format incorrect (must be DNS-compliant)
   - **Solution:** Check bucket naming in Terraform (lowercase, no underscores)

### Issue: S3 Permissions Denied

**Test S3 Access from Pod:**
```bash
# Exec into write pod
kubectl exec -it -n ghost-protocol-prod loki-write-0 -- sh

# Inside pod - test AWS credentials (from IRSA)
ls -la /var/run/secrets/eks.amazonaws.com/serviceaccount/

# Should show token file

# Test S3 access (requires AWS CLI in pod)
export AWS_REGION=us-east-1
aws s3 ls s3://ghost-protocol-prod-loki-chunks/

# Expected: List of objects or empty (for new bucket)
```

**Verify IAM Role Policy:**
```bash
# Get IAM role name
export ROLE_NAME=$(echo $LOKI_IRSA_ARN | cut -d'/' -f2)

# Check attached policies
aws iam list-attached-role-policies --role-name $ROLE_NAME

# Get policy document
aws iam get-role-policy --role-name $ROLE_NAME --policy-name loki-s3-access
```

### Issue: Memberlist Not Forming

**Check Logs:**
```bash
kubectl logs -n ghost-protocol-prod loki-write-0 | grep memberlist
```

**Expected:**
```
level=info msg="joining memberlist cluster" members=7
```

**If members < 7:**
- Check all pods are running
- Verify headless services exist
- Check network policies

## Validation Checklist

- [ ] Terraform outputs retrieved successfully
- [ ] Kustomize patches updated with actual values
- [ ] No placeholder strings remain in generated YAML
- [ ] All 7 Loki pods running (3 write, 3 read, 1 backend)
- [ ] ServiceAccount has correct IRSA role annotation
- [ ] S3 buckets accessible from pods
- [ ] Memberlist shows 7 members
- [ ] Logs successfully ingesting (check Grafana)
- [ ] Queries returning results from S3

## Rollback

If deployment fails:

```bash
# Rollback to old monolithic Loki
kubectl scale deployment loki --replicas=1 -n ghost-protocol-prod

# Delete new Loki HA components
kubectl delete -k infra/k8s/overlays/production

# Verify old Loki is running
kubectl get pods -n ghost-protocol-prod | grep loki
```

## Next Steps

After successful deployment:

1. **Update Grafana Datasource:**
   - URL: `http://loki-gateway:3100`
   
2. **Configure Monitoring:**
   - Import Loki dashboards (IDs: 13407, 12019)
   - Verify Prometheus alerts firing correctly
   
3. **Test Migration:**
   - Follow migration guide in `docs/runbooks/loki-ha-operations.md`
   - Implement dual-write for safety
   
4. **Cleanup Old Resources:**
   - After 7 days of stable operation, delete old monolithic deployment
   - Snapshot old PVCs before deletion

## Related Documentation

- [Loki HA Architecture](../../../../docs/architecture/loki-ha-architecture.md)
- [Loki HA Operations Runbook](../../../../docs/runbooks/loki-ha-operations.md)
- [Terraform Observability Module](../../../../terraform/modules/observability/aws/README.md)

---

**Last Updated:** 2025-11-16  
**Maintained By:** Platform Engineering Team
