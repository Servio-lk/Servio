#!/bin/bash

# Quick Fix for Docker Build Issues
# Specifically handles Maven download failures

echo "🔧 Servio Docker Build - Quick Fix"
echo "=================================="
echo ""

# Stop everything
echo "🛑 Stopping all containers..."
docker-compose down -v

# Clean Docker system
echo "🧹 Cleaning Docker system..."
docker system prune -f

# Remove corrupted images
echo "🗑️  Removing old backend image..."
docker rmi servio-backend 2>/dev/null || true

# Try building backend only first (most likely to fail)
echo ""
echo "🔨 Building backend (this may take a few minutes)..."
docker-compose build --no-cache --progress=plain backend

if [ $? -eq 0 ]; then
    echo "✅ Backend built successfully!"

    # Build frontend
    echo ""
    echo "🔨 Building frontend..."
    docker-compose build --no-cache frontend

    if [ $? -eq 0 ]; then
        echo "✅ Frontend built successfully!"

        # Start all services
        echo ""
        echo "🚀 Starting all services..."
        docker-compose up -d

        echo ""
        echo "✅ All done! Check status:"
        docker-compose ps
    else
        echo "❌ Frontend build failed"
        exit 1
    fi
else
    echo "❌ Backend build failed"
    echo ""
    echo "💡 This is likely a network issue. Try:"
    echo "   1. Check your internet connection"
    echo "   2. Wait a few minutes and try again"
    echo "   3. Use a different network if possible"
    echo "   4. Run this script again: ./docker-fix.sh"
    exit 1
fi
