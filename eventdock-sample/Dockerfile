# Eclipse Temurin 21 OpenJDK
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /workspace

RUN apk add --no-cache maven

COPY . .

# Build sample application
RUN mvn clean package -DskipTests -pl eventdock-sample -am

# Runtime Image
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S linkpeer && adduser -S linkpeer -G linkpeer
USER linkpeer:linkpeer

COPY --from=builder /workspace/eventdock-sample/target/eventdock-sample-*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
