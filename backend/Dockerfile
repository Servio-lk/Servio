# Build stage — $BUILDPLATFORM ensures Maven runs natively (no QEMU emulation)
# Java bytecode is platform-independent, so we can build on ARM64 and run on x86_64
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .

# Download dependencies with cache mount and retry logic in batch mode
RUN --mount=type=cache,target=/root/.m2 \
    for i in 1 2 3; do \
        mvn dependency:go-offline -B && break || \
        (echo "Dependency download attempt $i failed, retrying..." && sleep 5); \
    done

COPY src ./src

# Build with cache mount and retry logic
RUN --mount=type=cache,target=/root/.m2 \
    success=false; \
    for i in 1 2 3; do \
        if mvn clean package -DskipTests -B; then success=true; break; fi; \
        echo "Build attempt $i failed, retrying..." && sleep 5; \
    done; \
    $success || (echo "BUILD FAILED after 3 attempts" && exit 1)

# Production runtime stage
FROM eclipse-temurin:17-jre-jammy AS runner

WORKDIR /app

# dumb-init for proper signal handling and curl for healthcheck
RUN apt-get update \
    && apt-get install -y --no-install-recommends dumb-init curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create non-root system user
RUN groupadd -r -g 1001 appuser \
    && useradd -r -u 1001 -g appuser -d /app -s /usr/sbin/nologin appuser

# Copy application artifact with correct ownership
COPY --from=builder --chown=appuser:appuser /app/target/*.jar app.jar

USER appuser

EXPOSE 3001

# Health check using Spring Boot Actuator endpoint (port 3001)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3001/actuator/health || exit 1

# JVM tuned for containerized environments (AWS t3.micro compatible)
ENTRYPOINT ["dumb-init", "--", "java", \
  "-Djava.net.preferIPv4Stack=true", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=65.0", \
  "-XX:+ExitOnOutOfMemoryError", \
  "-jar", "app.jar"]
