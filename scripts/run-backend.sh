#!/bin/bash

# scripts/run-backend.sh
# Runs the Spring Boot Backend with Java 17 and environment variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting Servio Backend..."
cd "$REPO_ROOT/backend" || exit 1

# Force Java 17 if available on macOS
if [ -x "/usr/libexec/java_home" ]; then
    JAVA_HOME_17=$(/usr/libexec/java_home -v 17 2>/dev/null)
    if [ -n "$JAVA_HOME_17" ]; then
        export JAVA_HOME="$JAVA_HOME_17"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Using Java 17: $JAVA_HOME"
    fi
fi

# Determine active .env file (check backend/.env first, then root .env)
ENV_FILE=""
if [ -f "$REPO_ROOT/backend/.env" ]; then
  ENV_FILE="$REPO_ROOT/backend/.env"
elif [ -f "$REPO_ROOT/.env" ]; then
  ENV_FILE="$REPO_ROOT/.env"
fi

if [ -n "$ENV_FILE" ]; then
  while IFS='=' read -r key value; do
    # Skip blank lines and comments
    [[ -z "$key" || "$key" == \#* ]] && continue
    # Strip inline comments
    value="${value%%#*}"
    # Strip surrounding whitespace
    key="${key// /}"
    export "$key=$value"
  done < "$ENV_FILE"
  echo "✅ Loaded environment variables from $ENV_FILE"
else
  echo "⚠️  No .env file found. Ensure backend/.env or root .env is configured."
fi

# Run Spring Boot with Maven
mvn spring-boot:run
