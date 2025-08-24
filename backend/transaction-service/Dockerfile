# Multi-stage Docker build for Transaction Service
# Based on Eclipse Temurin official images and Docker best practices

# Stage 1: Build stage with JDK
FROM eclipse-temurin:17-jdk-alpine AS build

# Install Maven
RUN apk add --no-cache maven

# Set working directory
WORKDIR /app

# Copy parent POM and shared module first for better caching
COPY ../pom.xml ./pom.xml
COPY ../shared ./shared

# Copy service-specific files
COPY pom.xml ./transaction-service/pom.xml
COPY src ./transaction-service/src

# Build the shared module first
RUN mvn -f ./shared/pom.xml clean install -DskipTests

# Build the application
RUN mvn -f ./transaction-service/pom.xml clean package -DskipTests

# Stage 2: Runtime stage with JRE
FROM eclipse-temurin:17-jre-alpine AS runtime

# Install additional packages if needed
RUN apk add --no-cache \
    curl \
    tzdata

# Create non-root user
RUN addgroup -g 1002 -S appgroup && \
    adduser -S appuser -u 1002 -G appgroup

# Set working directory
WORKDIR /app

# Copy the built JAR file
COPY --from=build /app/transaction-service/target/*.jar app.jar

# Change ownership to non-root user
RUN chown appuser:appgroup app.jar

# Switch to non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 8082

# Set JVM options for containerized environment
ENV JAVA_OPTS="-Xms256m -Xmx512m -Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8082/actuator/health || exit 1

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]