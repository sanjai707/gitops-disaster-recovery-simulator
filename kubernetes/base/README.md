# Module 6: Kubernetes deployment manifests

This directory contains the minimal Kubernetes resources needed to run the
Spring Boot application on the single-node k3s environment created in Module 3.

## Included resources

- `namespace.yaml` creates the `gitops-dr-simulator` namespace.
- `deployment.yaml` runs one replica of the application container.
- `service.yaml` exposes the app internally on port `8080`.

## Image note

The manifest uses the image name `gitops-dr-simulator:local` because this project
has not yet published a registry-backed image. That image must exist on the k3s
node before the deployment is applied, or the image reference should be replaced
with a registry URL that the cluster can pull.

## Apply locally

The repository does not include a live k3s cluster in this environment, so this
step is intentionally documented but not executed here.

```bash
kubectl apply -f kubernetes/base/namespace.yaml
kubectl apply -f kubernetes/base/deployment.yaml
kubectl apply -f kubernetes/base/service.yaml
```

## Validation targets

The application exposes:

- `/api/health`
- `/api/info`
- `/api/ready`
- `/actuator/health`

These endpoints are used by future readiness and liveness checks, but this
Module 6 scope remains limited to deployment manifests only.
