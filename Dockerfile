# ================================
# Base build stage
# ================================
FROM amazoncorretto:21-alpine3.21-jdk AS base

WORKDIR /app

# Install Maven + Bash in one layer and set permissions for scripts
RUN apk add --no-cache maven bash

# Copy pom and download dependencies (cacheable)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and scripts
COPY src ./src
COPY test-table.sh ./test-table.sh
COPY test-coverage.sh ./test-coverage.sh

# Make scripts executable
RUN chmod +x ./test-table.sh ./test-coverage.sh

# ================================
# Development target
# ================================
FROM base AS dev

# In dev mode, run with Maven (hot reload if spring-boot-devtools is in pom.xml)
CMD ["mvn", "spring-boot:run", "-Dspring-boot.run.profiles=dev"]


# ================================
# Production build stage
# ================================
FROM base AS build

# Run tests and generate Jacoco report
# Run coverage scripts with bash
# Build the jar
RUN mvn clean test jacoco:report \
    && bash ./test-table.sh target/site/jacoco/jacoco.csv \
    && bash ./test-coverage.sh target/site/jacoco/jacoco.csv \
    && mvn clean package -DskipTests

# ================================
# Production runtime target
# ================================
FROM amazoncorretto:21-alpine3.21 AS prod
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
