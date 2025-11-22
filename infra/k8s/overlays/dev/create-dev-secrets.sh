#!/bin/bash
# Create development secrets (run locally, not committed)
# These secrets are for local development only and should not contain real credentials

set -e

NAMESPACE="ghost-protocol-dev"

echo "🔐 Creating development secrets for namespace: $NAMESPACE"
echo ""

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo "⚠️  Namespace $NAMESPACE does not exist. Creating it..."
  kubectl create namespace "$NAMESPACE"
fi

# Create database secret
echo "📦 Creating database-secret..."
kubectl create secret generic database-secret \
  --namespace="$NAMESPACE" \
  --from-literal=url="postgresql://ghostadmin:CHANGE_ME@postgres:5432/ghostprotocol_dev" \
  --from-literal=host="postgres" \
  --from-literal=port="5432" \
  --from-literal=database="ghostprotocol_dev" \
  --from-literal=username="ghostadmin" \
  --from-literal=password="CHANGE_ME" \
  --dry-run=client -o yaml | kubectl apply -f -

# Create redis secret
echo "📦 Creating redis-secret..."
kubectl create secret generic redis-secret \
  --namespace="$NAMESPACE" \
  --from-literal=url="redis://redis:6379" \
  --from-literal=host="redis" \
  --from-literal=port="6379" \
  --from-literal=password="" \
  --dry-run=client -o yaml | kubectl apply -f -

# Create AI engine secret
echo "📦 Creating ai-engine-secret..."
kubectl create secret generic ai-engine-secret \
  --namespace="$NAMESPACE" \
  --from-literal=openai-api-key="sk-CHANGE_ME" \
  --from-literal=huggingface-token="hf_CHANGE_ME" \
  --from-literal=model-encryption-key="dev-encryption-key-CHANGE_ME" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Development secrets created successfully!"
echo ""
echo "⚠️  IMPORTANT: These secrets contain placeholder values."
echo "   Update them with actual values for your development environment:"
echo ""
echo "   kubectl edit secret database-secret -n $NAMESPACE"
echo "   kubectl edit secret redis-secret -n $NAMESPACE"
echo "   kubectl edit secret ai-engine-secret -n $NAMESPACE"
echo ""
echo "💡 TIP: For local development, you can use Docker Compose to run PostgreSQL and Redis:"
echo "   docker-compose up -d postgres redis"
