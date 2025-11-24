# EFF API Automation

Simple Karate/Maven test suite that automates the EFF GraphQL flows such as signup, password reset, and verification APIs.

## Prerequisites
- Java 11+ (JDK) available on the `PATH`
- Apache Maven 3.9+
- Access credentials for the target environment (values for `BASE_URL` and `X_API_KEY`)

## Setup
1. Clone or download the repository onto your machine.
2. Create a `.env` file in the project root with the required variables:
   ```
   BASE_URL=<your_api_base_url>
   X_API_KEY=<your_api_key>
   ```
3. (Optional) Clean previous test artifacts: `mvn clean`

## Run All Tests
Execute the Karate suite through Maven:
```
mvn test
```
This uses the JUnit 5 runner at `src/test/java/Runners/TestRunner.java` to execute every feature file in one shot.

