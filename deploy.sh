#!/usr/bin/env bash
# CodeSpotlight — Firebase Frontend Build + Deploy Script
# Usage: BACKEND_URL=https://your-app.onrender.com/api bash deploy.sh
set -e

BACKEND="${BACKEND_URL:-https://codespotlight-backend.onrender.com/api}"

echo "🔧 Building Flutter Web with BACKEND_URL=$BACKEND"
cd frontend

flutter build web \
  --release \
  --dart-define=BACKEND_URL="$BACKEND"

echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo "✅ Deployed!"
