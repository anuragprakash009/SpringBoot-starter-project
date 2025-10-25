# ================================
# Base build stage
# ================================
FROM amazoncorretto:21-alpine3.21-jdk AS base
WORKDIR /app

# Install Maven
RUN apk add --no-cache maven

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
COPY test-table.sh ./test-table.sh
COPY test-coverage.sh ./test-coverage.sh

RUN chmod +x ./test-coverage.sh
RUN chmod +x ./test-table.sh

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

# Install bash in Alpine
RUN apk add --no-cache bash

# Run tests and generate Jacoco report
RUN mvn clean test jacoco:report

# Run coverage scripts with bash
RUN bash ./test-table.sh target/site/jacoco/jacoco.csv
RUN bash ./test-coverage.sh target/site/jacoco/jacoco.csv

# Build the jar
RUN mvn clean package -DskipTests

# ================================
# Production runtime target
# ================================
FROM amazoncorretto:21-alpine3.21-jdk AS prod
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
