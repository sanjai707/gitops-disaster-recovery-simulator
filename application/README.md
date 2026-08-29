# GitOps DR Demo Application

This small Spring Boot service is the workload used by the GitOps Disaster
Recovery Simulator. It provides observable HTTP behavior for later container,
Kubernetes, GitOps, and controlled recovery exercises.

The application currently has no database, authentication, frontend, or
Kubernetes deployment. Database integration is intentionally deferred until a
future persistence and multi-region design phase. Module 5 adds a local Docker
image; Kubernetes and GitOps deployment remain future work.

## Application Architecture

```text
HTTP request
    |
    v
Spring Boot controllers
    |
    +--> /api/health  static application health
    +--> /api/info    runtime identity and version
    +--> /api/ready   application readiness placeholder
    +--> /actuator/health
```

The `/api/info` response uses `HOSTNAME` when configured, which will later make
pod identity visible in Kubernetes. Without it, the application uses the local
system hostname and does not assume Kubernetes is present.

## Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/health` | Returns application status and name. |
| GET | `/api/info` | Returns application name, version, profile, and hostname. |
| GET | `/api/ready` | Reports application readiness without pretending to check a database. |
| GET | `/actuator/health` | Spring Boot health endpoint for future probes. |

Only the Actuator health endpoint is exposed. Sensitive Actuator endpoints are
not enabled.

## Environment Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `SERVER_PORT` | `8080` | HTTP server port. |
| `SPRING_PROFILES_ACTIVE` | `default` | Active Spring profile. |
| `APPLICATION_VERSION` | `0.1.0-SNAPSHOT` | Version returned by `/api/info`. |
| `DATABASE_URL` | empty | Reserved optional placeholder; it is not used yet and is not required. |
| `HOSTNAME` | system hostname | Optional runtime identity used by `/api/info`. |

Do not put credentials or passwords in these variables or in source control.

## Local Prerequisites

- Java 17 or newer
- Maven 3.9 or newer, or a compatible Maven wrapper added by a later change
- An available local TCP port, defaulting to `8080`

## Run Locally

From the `application/` directory:

```bash
mvn spring-boot:run
```

With environment configuration:

```bash
SERVER_PORT=8081 APPLICATION_VERSION=local-dev mvn spring-boot:run
```

On PowerShell:

```powershell
$env:SERVER_PORT = "8081"
$env:APPLICATION_VERSION = "local-dev"
mvn spring-boot:run
```

Example requests:

```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/info
curl http://localhost:8080/api/ready
curl http://localhost:8080/actuator/health
```

Expected responses include:

```json
{"status":"UP","application":"gitops-dr-simulator"}
```

```json
{"status":"UP","message":"Application is ready; database integration is deferred."}
```

The hostname and version in `/api/info` depend on the local environment.

## Tests And JAR Build

Run the focused tests:

```bash
mvn test
```

Build the executable JAR:

```bash
mvn clean package
java -jar target/gitops-dr-application-0.1.0-SNAPSHOT.jar
```

The build produces the JAR under `target/`, which is ignored locally.

## Logging And Shutdown

Spring Boot's normal logging records startup and graceful shutdown. The
application does not log secrets or complete environment variables. Graceful
shutdown is enabled with `server.shutdown: graceful`, allowing future
Kubernetes rolling updates, scaling, and failover workflows to stop the service
cleanly.

## Docker Container

Module 5 uses a two-stage Docker build. The Maven builder stage resolves
dependencies, compiles the source, runs tests, and packages the executable JAR.
The runtime stage contains only the Java 17 runtime and that JAR, so Maven,
source code, tests, and the Maven cache are not included in the final image.

Dependency descriptor files are copied before source files. Docker can reuse the
dependency layer when only application source changes; the source and package
layers are rebuilt as needed.

Build the image from the repository root:

```bash
docker build -t gitops-dr-simulator:local ./application
```

Run it as the non-root container user:

```bash
docker run --name gitops-dr-application-local -p 8080:8080 \
    -e APPLICATION_VERSION=container-local \
    -e SPRING_PROFILES_ACTIVE=default \
    gitops-dr-simulator:local
```

`SERVER_PORT` may be changed for an internal container port, but the published
port must match it. `DATABASE_URL` remains optional and is not used by this
module. Do not pass secrets or AWS credentials into the image build or commit
them to the repository.

Test the running container:

```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/info
curl http://localhost:8080/api/ready
curl http://localhost:8080/actuator/health
```

Stop and remove the local test container:

```bash
docker rm --force gitops-dr-application-local
```

The runtime image intentionally has no Docker `HEALTHCHECK`. The selected JRE
image does not include `curl` or `wget`, and adding a client solely for a
duplicate container-level check would make the image less minimal. The
Actuator endpoint is available for later Kubernetes liveness and readiness
probes, which are separate from Docker HEALTHCHECK configuration.

The image is built for the Docker host's default architecture. No multi-platform
image has been built or verified in this module.

## Future Modules

A future module will add Kubernetes manifests and Argo CD configuration. Those
modules will use the existing health endpoints for probes and GitOps recovery
demonstrations.

There is intentionally no database connection, replication, RTO/RPO result,
Kubernetes deployment, or multi-region failover in Module 4.
