# Build stage — $BUILDPLATFORM ensures Maven runs natively (no QEMU emulation)
# Java bytecode is platform-independent, so we can build on ARM64 and run on x86_64
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .

# Download dependencies with retry logic
RUN --mount=type=cache,target=/root/.m2 \
    for i in 1 2 3; do \
        mvn dependency:go-offline && break || \
        (echo "Attempt $i failed, retrying..." && sleep 5); \
    done

COPY src ./src

# Build with retry logic — fail explicitly if all attempts fail
RUN --mount=type=cache,target=/root/.m2 \
    success=false; \
    for i in 1 2 3; do \
        if mvn clean package -DskipTests; then success=true; break; fi; \
        echo "Build attempt $i failed, retrying..." && sleep 5; \
    done; \
    $success || (echo "BUILD FAILED after 3 attempts" && exit 1)

# Production stage — uses $TARGETPLATFORM (set via: docker build --platform linux/amd64)
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# dumb-init for proper signal handling
RUN apt-get update && apt-get install -y --no-install-recommends dumb-init curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/*.jar app.jar

# Create non-root user
RUN groupadd -r -g 1001 appuser \
    && useradd -r -u 1001 -g appuser -d /nonexistent -s /usr/sbin/nologin appuser
USER appuser

EXPOSE 3001

# Health check — matches server.port=3001
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3001/api/services || exit 1

# JVM tuned for AWS t3.micro (1 GB RAM total, ~512 MB for JVM)
ENTRYPOINT ["dumb-init", "--", "java", \
  "-Djava.net.preferIPv4Stack=true", \
  "-Xms128m", "-Xmx384m", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=50.0", \
  "-jar", "app.jar"]

