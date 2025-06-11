#!/bin/bash
# Deployment script for CarVilla web application (customized)

# Cek input
if [ $# -lt 1 ]; then
  echo "Usage: $0 <build_number> [rebuild]"
  echo "Example: $0 19"
  echo "Add 'rebuild' as second parameter to force rebuilding the image locally"
  exit 1
fi

BUILD_NUMBER=$1
REBUILD=${2:-no}
REPO_DIR="$HOME/carvilla"  # Ganti dengan path lokalmu
REGISTRY="localhost:30500"  # Pastikan ini sesuai dengan registry kamu
IMAGE_NAME="carvilla"

cd "$REPO_DIR" || { echo "Directory $REPO_DIR not found!"; exit 1; }

echo "Deploying build #$BUILD_NUMBER"

# Cek apakah perlu build ulang
NEED_REBUILD="no"
if [[ "$REBUILD" == "rebuild" ]]; then
  NEED_REBUILD="yes"
  echo "Rebuilding image locally..."
else
  echo "Checking if image exists in registry..."
  if curl -s -f "http://${REGISTRY}/v2/${IMAGE_NAME}/manifests/${BUILD_NUMBER}" > /dev/null; then
    echo "Image found in registry."
  else
    echo "⚠️ Image not found in registry. Build locally? (y/n)"
    read -r answer
    if [[ "$answer" == "y" ]]; then
      NEED_REBUILD="yes"
    else
      echo "Continue without rebuilding? (y/n)"
      read -r answer
      [[ "$answer" != "y" ]] && echo "Aborted." && exit 1
    fi
  fi
fi

# Build jika perlu
if [[ "$NEED_REBUILD" == "yes" ]]; then
  docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} .
  docker tag ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:latest

  echo "Push image ke registry? (y/n)"
  read -r answer
  [[ "$answer" == "y" ]] && docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} && docker push ${REGISTRY}/${IMAGE_NAME}:latest
fi

# Update deployment file
echo "Replacing build number in manifest..."
sed -i "s|\${BUILD_NUMBER}|${BUILD_NUMBER}|g" kubernetes/deployment.yaml

# Deploy ke Kubernetes
echo "Applying manifests..."
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Tunggu rollout
kubectl rollout status deployment/carvilla-web --timeout=60s || echo "⚠️ Deployment belum selesai."

# Cek status
kubectl get pods -l app=carvilla-web
kubectl get svc carvilla-web-service

echo "✅ Deployed! Access via: http://localhost:32123"
