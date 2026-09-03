#!/bin/bash

# Quick Fix for Docker Build Issues
# Cleans corrupted build cache and rebuilds services with Compose v2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 1

echo "🔧 Servio Docker Build - Quick Fix"
echo "=================================="
echo ""

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Stop everything
echo "🛑 Stopping all containers..."
docker compose down -v 2>/dev/null || true

# Clean Docker build cache
echo "🧹 Pruning dangling builder caches..."
docker builder prune -f

# Build backend first
echo ""
echo "🔨 Building backend with plain progress..."
if docker compose build --no-cache --progress=plain backend; then
    echo "✅ Backend built successfully!"
else
    echo "❌ Backend build failed."
    exit 1
fi

# Build frontend
echo ""
echo "🔨 Building frontend..."
if docker compose build --no-cache frontend; then
    echo "✅ Frontend built successfully!"
else
    echo "❌ Frontend build failed."
    exit 1
fi

# Start all services
echo ""
echo "🚀 Starting all services..."
docker compose up -d

echo ""
echo "✅ All done! Status:"
docker compose ps
