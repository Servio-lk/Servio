#!/bin/bash

# Docker Build Helper Script
# Builds Servio services using Docker BuildKit and Compose v2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 1

echo "🐳 Servio Docker Build Helper (Compose v2 + BuildKit)"
echo "====================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Stop running containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker compose down

# Build services using BuildKit parallel caching
echo ""
echo -e "${YELLOW}🔨 Building services with Docker BuildKit...${NC}"

if docker compose build; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed. Retrying with --no-cache...${NC}"
    docker compose build --no-cache
fi

# Start services
echo ""
echo -e "${YELLOW}🚀 Starting services...${NC}"
docker compose up -d

# Show status
echo ""
echo -e "${GREEN}✅ All services started!${NC}"
echo ""
echo "📊 Container Status:"
docker compose ps

echo ""
echo -e "${YELLOW}💡 Useful commands:${NC}"
echo "  View logs:     docker compose logs -f [service]"
echo "  Backend logs:  docker compose logs -f backend"
echo "  Frontend logs: docker compose logs -f frontend"
echo "  Stop all:      docker compose down"
echo "  Restart:       docker compose restart [service]"
echo ""
