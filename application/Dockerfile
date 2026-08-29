FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /build

# Resolve dependencies before copying source so dependency layers can be reused.
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B clean package

FROM eclipse-temurin:17-jre-jammy AS runtime

WORKDIR /app

RUN groupadd --system --gid 10001 appuser \
    && useradd --system --uid 10001 --gid 10001 --home-dir /app --no-create-home appuser

COPY --from=builder /build/target/*.jar app.jar

USER 10001:10001
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]