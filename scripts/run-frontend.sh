#!/bin/bash

# scripts/run-frontend.sh
# Runs the Vite Frontend

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting Servio Frontend..."

cd "$REPO_ROOT/frontend" || exit 1

# Install dependencies if not present
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Run dev server
npm run dev
