# Build stage
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

# Production stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
RUN apk add --no-cache dumb-init

COPY --from=builder /app/target/*.jar app.jar

RUN addgroup -g 1001 -S appuser && adduser -S appuser -u 1001
USER appuser

EXPOSE 8080

ENTRYPOINT ["dumb-init", "--", "java", "-jar", "app.jar"]
