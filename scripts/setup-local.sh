#!/bin/bash

# setup-local.sh
# Checks dependencies and readiness for local development

echo "🔍 Checking local environment..."

# 1. Check & Force Java 17
if [ -x "/usr/libexec/java_home" ]; then
    # Try to find Java 17 specifically
    JAVA_HOME_17=$(/usr/libexec/java_home -v 17 2>/dev/null)
    if [ ! -z "$JAVA_HOME_17" ]; then
        export JAVA_HOME="$JAVA_HOME_17"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Switched to Java 17: $JAVA_HOME"
    fi
fi

if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed. Please install Java 17."
    exit 1
fi

JAVA_VER=$(java -version 2>&1 | head -n 1)
echo "✅ Using Java: $JAVA_VER"

if [[ "$JAVA_VER" == *"build 25"* ]]; then
    echo "⚠️  WARNING: You are using Java 25. This WILL cause build failures."
    echo "    Please ensure Java 17 is installed and selected."
fi
if [[ "$JAVA_VER" == *"1.8"* || "$JAVA_VER" == *"11."* ]]; then
    echo "❌ ERROR: Spring Boot 3 requires Java 17 or higher. You are using an older version."
    exit 1
fi

# 2. Check Maven
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed. Please install Maven."
    exit 1
fi
echo "✅ Maven found: $(mvn -version | head -n 1)"

# 3. Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js."
    exit 1
fi
echo "✅ Node.js found: $(node -v)"

# 4. Check Environment Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$REPO_ROOT/backend/.env" ] || [ -f "$REPO_ROOT/.env" ]; then
   echo "✅ Environment configuration (.env) detected."
else
   echo "⚠️  No .env file found. Copy .env.example to .env and configure your database and API keys."
fi

echo ""
echo "🎉 Setup check complete! You can now run the backend and frontend."
echo "   - Run Backend:  ./scripts/run-backend.sh"
echo "   - Run Frontend: ./scripts/run-frontend.sh"
echo "   - Or Docker:    docker-compose up --build"
