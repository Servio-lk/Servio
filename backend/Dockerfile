# Build stage
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

COPY pom.xml .

# Download dependencies with retry logic
RUN --mount=type=cache,target=/root/.m2 \
    for i in 1 2 3; do \
        mvn dependency:go-offline && break || \
        (echo "Attempt $i failed, retrying..." && sleep 5); \
    done

COPY src ./src

# Build with retry logic
RUN --mount=type=cache,target=/root/.m2 \
    for i in 1 2 3; do \
        mvn clean package -DskipTests && break || \
        (echo "Build attempt $i failed, retrying..." && sleep 5); \
    done

# Production stage — Alpine JRE for smaller image (~80MB less)
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# dumb-init for proper signal handling (Alpine uses apk)
RUN apk add --no-cache dumb-init curl

COPY --from=builder /app/target/*.jar app.jar

# Create non-root user (Alpine syntax)
RUN addgroup -S -g 1001 appuser \
  && adduser -S -u 1001 -G appuser -h /nonexistent -D appuser
USER appuser

EXPOSE 3001

# Health check — matches server.port=3001
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3001/api/services || exit 1

# JVM tuned for AWS t2.micro (1 GB RAM total, ~512 MB for JVM)
ENTRYPOINT ["dumb-init", "--", "java", \
  "-Xms128m", "-Xmx384m", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=50.0", \
  "-jar", "app.jar"]
