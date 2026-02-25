#!/bin/bash

# run-backend.sh
# Runs the Spring Boot Backend with Java 17 and Supabase environment

echo "🚀 Starting Servio Backend..."
cd backend || exit

# Force Java 17
if [ -x "/usr/libexec/java_home" ]; then
    JAVA_HOME_17=$(/usr/libexec/java_home -v 17 2>/dev/null)
    if [ -n "$JAVA_HOME_17" ]; then
        export JAVA_HOME="$JAVA_HOME_17"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Using Java 17: $JAVA_HOME"
    fi
fi

# Safely load environment variables from .env (handles special chars and commas)
if [ -f .env ]; then
  while IFS='=' read -r key value; do
    # Skip blank lines and comments
    [[ -z "$key" || "$key" == \#* ]] && continue
    # Strip inline comments from value
    value="${value%%#*}"
    # Strip surrounding whitespace
    key="${key// /}"
    # Export the variable
    export "$key=$value"
  done < .env
  echo "✅ Loaded environment variables from .env"
else
  echo "⚠️  No backend/.env found. Copy backend/.env.example to backend/.env and fill in your Supabase credentials."
  exit 1
fi

# Run with Maven
mvn spring-boot:run
