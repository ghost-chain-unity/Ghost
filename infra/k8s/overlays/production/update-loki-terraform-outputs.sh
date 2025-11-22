#!/usr/bin/env bash
# Automated script to inject Terraform outputs into Loki Kustomize patches
# This ensures production overlay uses actual AWS resources created by Terraform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../../../terraform/environments/production"

echo "🔍 Fetching Terraform outputs from: $TERRAFORM_DIR"

# Validate Terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "❌ Error: Terraform directory not found: $TERRAFORM_DIR"
  exit 1
fi

# Navigate to Terraform directory
cd "$TERRAFORM_DIR"

# Get Terraform outputs
echo "📥 Retrieving Terraform outputs..."

LOKI_CHUNKS_BUCKET=$(terraform output -raw loki_chunks_bucket_name 2>/dev/null || echo "")
LOKI_RULER_BUCKET=$(terraform output -raw loki_ruler_bucket_name 2>/dev/null || echo "")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
LOKI_IRSA_ARN=$(terraform output -raw loki_irsa_role_arn 2>/dev/null || echo "")

# Validate outputs
if [ -z "$LOKI_CHUNKS_BUCKET" ] || [ -z "$LOKI_RULER_BUCKET" ] || [ -z "$LOKI_IRSA_ARN" ]; then
  echo "❌ Error: Missing required Terraform outputs. Please apply Terraform first."
  echo "   Chunks Bucket: ${LOKI_CHUNKS_BUCKET:-[MISSING]}"
  echo "   Ruler Bucket: ${LOKI_RULER_BUCKET:-[MISSING]}"
  echo "   AWS Region: ${AWS_REGION:-[MISSING]}"
  echo "   IRSA ARN: ${LOKI_IRSA_ARN:-[MISSING]}"
  exit 1
fi

echo "✅ Retrieved Terraform outputs:"
echo "   Chunks Bucket: $LOKI_CHUNKS_BUCKET"
echo "   Ruler Bucket: $LOKI_RULER_BUCKET"
echo "   AWS Region: $AWS_REGION"
echo "   IRSA ARN: $LOKI_IRSA_ARN"

# Return to overlay directory
cd "$SCRIPT_DIR"

# Backup original patches
echo "💾 Creating backups..."
cp loki-config-patch.yaml loki-config-patch.yaml.bak 2>/dev/null || true
cp loki-sa-patch.yaml loki-sa-patch.yaml.bak 2>/dev/null || true

# Update loki-config-patch.yaml with actual values
echo "🔧 Updating loki-config-patch.yaml..."
sed -i.tmp \
  -e "s|s3://[a-z0-9\-]*loki-chunks|s3://$LOKI_CHUNKS_BUCKET|g" \
  -e "s|bucketnames: [a-z0-9\-]*loki-ruler|bucketnames: $LOKI_RULER_BUCKET|g" \
  -e "s|region: [a-z0-9\-]*|region: $AWS_REGION|g" \
  loki-config-patch.yaml
rm -f loki-config-patch.yaml.tmp

# Update loki-sa-patch.yaml with actual IRSA ARN
echo "🔧 Updating loki-sa-patch.yaml..."
sed -i.tmp \
  -e "s|eks.amazonaws.com/role-arn:.*|eks.amazonaws.com/role-arn: $LOKI_IRSA_ARN|g" \
  loki-sa-patch.yaml
rm -f loki-sa-patch.yaml.tmp

echo "✅ Patches updated successfully!"
echo ""
echo "🔍 Validating kustomization..."
kubectl kustomize . > /tmp/loki-ha-production-output.yaml 2>/dev/null || {
  echo "⚠️  Warning: kubectl kustomize validation failed. Install kubectl to validate."
}

# Verify no placeholders remain
if grep -qE "ACCOUNT_ID|PLACEHOLDER|TODO|ghost-protocol-prod-loki" loki-config-patch.yaml loki-sa-patch.yaml 2>/dev/null; then
  echo "⚠️  Warning: Some placeholders may still exist. Please review patches manually."
else
  echo "✅ No placeholders detected in patches"
fi

echo ""
echo "📋 Next steps:"
echo "   1. Review updated patches: git diff loki-config-patch.yaml loki-sa-patch.yaml"
echo "   2. Validate kustomization: kubectl kustomize infra/k8s/overlays/production"
echo "   3. Apply to cluster: kubectl apply -k infra/k8s/overlays/production"
echo ""
echo "✨ Done!"
