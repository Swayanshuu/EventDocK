# Eclipse Temurin 21 OpenJDK
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /workspace

# Install maven
RUN apk add --no-cache maven

COPY . .

# Build API artifact
RUN mvn clean package -DskipTests -pl eventdock-api -am

# Runtime Image
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Non-root user for security
RUN addgroup -S eventdock && adduser -S eventdock -G eventdock
USER eventdock:eventdock

COPY --from=builder /workspace/eventdock-api/target/eventdock-api-0.1.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-XX:+UseZGC", "-XX:+ZGenerational", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
