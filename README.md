# GitOps Disaster Recovery Simulator

A production-inspired learning project that demonstrates how version-controlled
infrastructure and Kubernetes application state can be recreated after a
simulated failure. The project uses Terraform, k3s, Argo CD, Prometheus,
Grafana, and controlled chaos tests to measure recovery behavior.

The goal is an interview-ready demonstration, not a claim of production
availability:

> I built a GitOps-driven disaster recovery simulator where infrastructure and
> application state are recreated from Git, failures are controlled, and
> measured recovery behavior is recorded in reports.

## Architecture

### Current Development Architecture

Development runs in `ap-south-1` on one Ubuntu EC2 instance with a single-node
k3s cluster. This keeps the environment understandable and inexpensive, but
the EC2 instance and Kubernetes control plane are single points of failure.

```text
Developer
	 |
	 +--> GitHub --> GitHub Actions (test and publish image)
	 |                  |
	 |                  v
	 |              Container Registry
	 |
	 +--> Argo CD watches Git desired state
													|
													v
							Single EC2 instance running k3s
								 |       |       |
								 v       v       v
						 Application Prometheus Grafana
								 |
								 v
					Health checks and chaos scenarios
```

Terraform provisions the VPC, public subnet, routing, security group, and EC2
host. Kubernetes manifests and Helm-based components are managed separately by
Argo CD. No NAT Gateway or Amazon EKS cluster is required for normal
development.

### Future Validation Architecture

The optional production-style validation environment will use separate
Terraform configuration for two AWS regions:

```text
Users
	|
	v
Route 53 failover and health checks
	|                         |
	v                         v
Primary region EKS      Secondary region EKS
	|                         |
	+------ replicated database strategy ------+
```

Possible database strategies are Aurora Global Database or an RDS cross-region
read replica with promotion. Database access still uses VPC networking in each
region; cross-region replication is the global part of the design. This phase
is intentionally not created by default because it can incur significant AWS
cost.

## Objectives

- Provision reproducible AWS infrastructure with Terraform.
- Run a low-cost, single-node k3s development environment.
- Deploy a sample Spring Boot service through Argo CD.
- Build and test the container with GitHub Actions.
- Observe node, pod, and application health with Prometheus and Grafana.
- Simulate controlled application and Kubernetes failures.
- Measure recovery in the simulated environment and produce JSON/Markdown
	reports.
- Document limitations and a credible path to multi-region validation.

## Technology Stack

| Area | Technology |
| --- | --- |
| Infrastructure | Terraform, AWS VPC, EC2 |
| Kubernetes | k3s, kubectl |
| GitOps | Argo CD, GitHub |
| Application | Java, Spring Boot, Maven, Docker |
| Observability | Prometheus, Grafana |
| Testing | Python health checks and chaos scripts |

## Disaster Recovery Concepts

- **RTO (Recovery Time Objective):** the measured time from failure injection
	to application health returning in a test. It is an observed result, not an
	enterprise SLA.
- **RPO (Recovery Point Objective):** the maximum acceptable amount of data
	loss. The initial stateless application has no meaningful RPO measurement
	because it has no persistent data to recover.
- **Failover:** directing operation to a healthy alternate environment or
	component after a failure. The initial single-node setup cannot provide true
	regional failover.
- **Recovery:** restoring the desired infrastructure or application state and
	verifying health again.

Before chaos tests run, recovery results are intentionally shown as:

```text
RTO: TBD - measure after executing a chaos scenario
RPO: Not applicable for the initial stateless application
```

## Implementation Phases

1. **Foundation:** repository structure, scope, architecture, and documentation.
2. **Infrastructure:** low-cost AWS network and EC2 host with Terraform.
3. **Platform:** bootstrap the single-node k3s development environment.
4. **Application:** build the Spring Boot service and container image.
5. **Delivery:** add CI, Kubernetes manifests, and Argo CD synchronization.
6. **Observability:** deploy monitoring and application availability checks.
7. **Recovery testing:** add controlled chaos scenarios and RTO reports.
8. **Future validation:** document and optionally implement a short-lived
	 multi-region EKS exercise with a persistence strategy.

## Cost And Security Notes

- The default path uses one EC2 instance and avoids NAT Gateways and EKS fees.
- AWS resources must be reviewed with `terraform plan` before applying and
	removed with `terraform destroy` after testing.
- SSH access must use a personal public IP in a `/32` CIDR, never
	`0.0.0.0/0`.
- AWS credentials come from the AWS CLI credential chain, environment, or an
	attached IAM role. Credentials, private keys, Terraform state, and secrets
	must never be committed.
- Public HTTP/HTTPS exposure should be enabled only when the demonstration
	needs it; keep other access private.
- A multi-region EKS/database demonstration should be created only for a short
	validation window and destroyed immediately afterward.

## Repository Structure

```text
application/   Spring Boot service and Dockerfile
chaos/         Controlled failure scripts and recovery reports
diagrams/      Architecture source and rendered diagram
docs/          Architecture, DR, testing, and interview notes
kubernetes/    Argo CD, application, monitoring, and policy manifests
monitoring/    Prometheus configuration and Grafana dashboards
terraform/     AWS development infrastructure
scripts/       Bootstrap, deployment, health-check, and cleanup helpers
```

## Roadmap

- [x] Define the project scope and development architecture.
- [ ] Provision the disposable AWS development host.
- [ ] Bootstrap single-node k3s.
- [ ] Deploy and monitor the sample application with GitOps.
- [ ] Run controlled failure scenarios and publish measured reports.
- [ ] Document a separate, optional multi-region EKS validation design.

## Current Status

Module 1, project foundation, is in progress. Terraform files are present as
the starting point for Module 2, but no AWS resources should be created until
the Terraform plan has been reviewed.