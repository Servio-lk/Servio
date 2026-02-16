#!/bin/bash

# run-backend.sh
# Runs the Spring Boot Backend

echo "🚀 Starting Servio Backend..."
cd backend || exit

# Force Java 17
if [ -x "/usr/libexec/java_home" ]; then
    JAVA_HOME_17=$(/usr/libexec/java_home -v 17 2>/dev/null)
    if [ ! -z "$JAVA_HOME_17" ]; then
        export JAVA_HOME="$JAVA_HOME_17"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Using Java 17: $JAVA_HOME"
    fi
fi

# Load environment variables from .env if present
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
  echo "✅ Loaded environment variables from .env"
fi

# Run with Maven
mvn spring-boot:run
