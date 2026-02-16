# Build stage
FROM maven:3.9-eclipse-temurin-17 AS builder

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

# Production stage
FROM eclipse-temurin:17-jre

WORKDIR /app
RUN apt-get update && apt-get install -y dumb-init && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/*.jar app.jar

# Create non-root user/group with predictable ids (Debian syntax)
RUN addgroup --system --gid 1001 appuser \
  && adduser --system --uid 1001 --ingroup appuser --home /nonexistent --disabled-password appuser
USER appuser

EXPOSE 8080

ENTRYPOINT ["dumb-init", "--", "java", "-jar", "app.jar"]
