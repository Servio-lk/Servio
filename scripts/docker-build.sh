#!/bin/bash

# Docker Build Helper Script
# This script helps build Docker images with better error handling and retries

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 1

echo "🐳 Servio Docker Build Helper"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to pull image with retry
pull_with_retry() {
    local image=$1
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo -e "${YELLOW}📦 Pulling $image (attempt $attempt/$max_attempts)...${NC}"
        if docker pull $image; then
            echo -e "${GREEN}✅ Successfully pulled $image${NC}"
            return 0
        else
            echo -e "${RED}❌ Failed to pull $image (attempt $attempt/$max_attempts)${NC}"
            attempt=$((attempt + 1))
            if [ $attempt -le $max_attempts ]; then
                echo "Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    echo -e "${RED}❌ Failed to pull $image after $max_attempts attempts${NC}"
    return 1
}

# Stop running containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker-compose down

# Pull required images
echo ""
echo -e "${YELLOW}📥 Pulling required Docker images...${NC}"
echo ""

pull_with_retry "node:20-alpine" || {
    echo -e "${RED}Failed to pull node:20-alpine. Trying node:20...${NC}"
    pull_with_retry "node:20"
}

pull_with_retry "nginx:alpine"
pull_with_retry "maven:3.9-eclipse-temurin-17"
pull_with_retry "eclipse-temurin:17-jre"

# Clean up any corrupted Maven cache in containers
echo ""
echo -e "${YELLOW}🧹 Cleaning up...${NC}"
docker-compose down -v 2>/dev/null || true

# Build with retry logic
echo ""
echo -e "${YELLOW}🔨 Building services...${NC}"
max_build_attempts=3
build_attempt=1

while [ $build_attempt -le $max_build_attempts ]; do
    echo -e "${YELLOW}Building (attempt $build_attempt/$max_build_attempts)...${NC}"

    if docker-compose build --no-cache; then
        echo -e "${GREEN}✅ Build successful!${NC}"
        break
    else
        echo -e "${RED}❌ Build failed (attempt $build_attempt/$max_build_attempts)${NC}"
        build_attempt=$((build_attempt + 1))

        if [ $build_attempt -le $max_build_attempts ]; then
            echo "Cleaning and retrying in 10 seconds..."
            docker system prune -f
            sleep 10
        else
            echo -e "${RED}❌ Build failed after $max_build_attempts attempts${NC}"
            echo ""
            echo "💡 Try manually:"
            echo "  1. docker-compose down -v"
            echo "  2. docker system prune -af"
            echo "  3. docker-compose build --no-cache backend"
            exit 1
        fi
    fi
done

# Start services
echo ""
echo -e "${YELLOW}🚀 Starting services...${NC}"
docker-compose up -d

# Show status
echo ""
echo -e "${GREEN}✅ All services started!${NC}"
echo ""
echo "📊 Container Status:"
docker-compose ps

echo ""
echo -e "${YELLOW}💡 Useful commands:${NC}"
echo "  View logs: docker-compose logs -f [service]"
echo "  Backend logs: docker-compose logs -f backend"
echo "  Frontend logs: docker-compose logs -f frontend"
echo "  Stop all: docker-compose down"
echo "  Restart: docker-compose restart [service]"
echo ""
