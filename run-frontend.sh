#!/bin/bash

# run-frontend.sh
# Runs the Vite Frontend

echo "🚀 Starting Servio Frontend..."

cd frontend || exit

# Install dependencies if not present
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Run dev server
npm run dev
