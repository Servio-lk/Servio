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

# Ensure we are using the local configuration
export DB_HOST=localhost
export DB_PORT=5433
export DB_NAME=servio_db
export DB_USER=servio_user
export DB_PASSWORD=servio_password
export PORT=3001

# Run with Maven
mvn spring-boot:run
