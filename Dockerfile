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
RUN mvn clean package -DskipTests


# ================================
# Production runtime target
# ================================
FROM amazoncorretto:21-alpine3.21-jdk AS prod
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
