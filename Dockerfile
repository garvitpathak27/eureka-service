# syntax=docker/dockerfile:1.7

# ---------------------------------------------------------------------------
# Stage 1: builder. Uses the committed Maven wrapper so the build version
# matches what you run locally (3.9.16, per .mvn/wrapper/maven-wrapper.properties).
# ---------------------------------------------------------------------------
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -B dependency:go-offline

COPY src ./src
RUN ./mvnw -B -DskipTests package && \
    mv target/*.jar target/app.jar

# ---------------------------------------------------------------------------
# Stage 2: runtime. JRE only — no Maven, no JDK compiler.
# ---------------------------------------------------------------------------
FROM eclipse-temurin:21-jre AS runtime

RUN groupadd --system eureka && \
    useradd --system --gid eureka --home-dir /app --shell /sbin/nologin eureka

WORKDIR /app
COPY --from=builder --chown=eureka:eureka /app/target/app.jar ./app.jar

USER eureka
EXPOSE 8761

CMD ["java", "-jar", "app.jar"]

