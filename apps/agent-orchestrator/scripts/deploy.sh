#!/bin/bash

# Configuration
# Dynamically get active gcloud project, fallback to environment variable or 'planing-agent'
ACTIVE_PROJECT=$(gcloud config get-value project 2>/dev/null)
PROJECT_ID="${GCP_PROJECT_ID:-${ACTIVE_PROJECT:-planing-agent}}"
SERVICE_NAME="agent-orchestrator"
REGION="asia-southeast1"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

echo "🚀 Starting Deployment for $SERVICE_NAME to $REGION..."

# 0. Check for gcloud auth
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "❌ You are not logged in to gcloud. Please run: gcloud auth login"
    exit 1
fi

# 1. Change to the backend directory where Dockerfile resides
cd "$(dirname "$0")/.." || exit

# 2. Prepare Environment Variables from .env
if [ ! -f .env ]; then
    echo "❌ .env file not found! Please create one in the current directory."
    exit 1
fi

# Convert .env to a comma-separated list for gcloud
# Excludes comments and empty lines
ENV_VARS=$(grep -v '^#' .env | grep -v '^$' | xargs | sed 's/ /,/g')

echo "📦 Building container image via Cloud Build..."
gcloud builds submit --tag "$IMAGE_NAME" . --project "$PROJECT_ID"

echo "☁️ Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
    --image "$IMAGE_NAME" \
    --platform managed \
    --region "$REGION" \
    --allow-unauthenticated \
    --set-env-vars="$ENV_VARS" \
    --project "$PROJECT_ID"

echo "✅ Deployment complete!"
# Get the URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --platform managed --region "$REGION" --format 'value(status.url)' --project "$PROJECT_ID")
echo "🔗 Service URL: $SERVICE_URL"
echo "👉 Update apps/frontend/lib/core/config/api_config.dart with this URL."
