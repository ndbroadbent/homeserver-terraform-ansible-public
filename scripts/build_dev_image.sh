#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities
# shellcheck disable=SC1091
source "$(dirname "$0")/shared/common.sh"

# Configuration
DOCKER_IMAGE_NAME="youruser/homeserver-dev"
DOCKER_TAG="latest"

# Ensure buildx is available
if ! docker buildx version >/dev/null 2>&1; then
  echo "Docker Buildx is required. Please install Docker Buildx."
  exit 1
fi

echo "🔨 Building multi-arch development Docker image..."

# Check if builder exists and use it, or create it if it doesn't
if docker buildx inspect multiarch-builder >/dev/null 2>&1; then
  docker buildx use multiarch-builder
else
  docker buildx create --use --name multiarch-builder
fi

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "${DOCKER_IMAGE_NAME}:${DOCKER_TAG}" \
  -f Dockerfile.dev \
  --push .

echo "✅ Multi-arch image built and pushed as ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"

log "$GREEN" "✅ Image built successfully:"
log "$GREEN" "   ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"

# Push to Docker Hub
# log "$BLUE" "📤 Pushing images to Docker Hub..."
# docker push "${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"

log "$GREEN" "✅ Images pushed successfully!"
log "$GREEN" "   You can now use this image in your CI workflow:"
log "$GREEN" "   image: ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"

log "$GREEN" "🎉 Development image build complete!" 
