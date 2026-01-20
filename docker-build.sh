#!/bin/bash

# Docker Build Helper Script
# This script helps build Docker images with better error handling and retries

set -e

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

# Build and start services
echo ""
echo -e "${YELLOW}🔨 Building and starting services...${NC}"
docker-compose up -d --build

# Show status
echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "📊 Container Status:"
docker-compose ps

echo ""
echo -e "${YELLOW}💡 Useful commands:${NC}"
echo "  View logs: docker-compose logs -f"
echo "  Stop all: docker-compose down"
echo "  Restart: docker-compose restart"
echo ""
