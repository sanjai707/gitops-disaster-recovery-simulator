# Module 3: EC2 Bootstrap and k3s

This module prepares the Terraform-created Ubuntu EC2 instance as a
single-node k3s development environment. It installs the minimum dependencies,
installs or starts k3s, configures private kubectl access for the EC2 user, and
verifies the service, Kubernetes API, node readiness, and system pods.

The script will eventually run on the EC2 host after the infrastructure has
been created and SSH access has been verified. It is intentionally separate
from Terraform so infrastructure provisioning and host configuration remain
easy to explain and troubleshoot.

## Prerequisites

- Ubuntu or Debian-compatible EC2 instance created by Module 2.
- Root access, normally through `sudo` over SSH.
- Outbound HTTPS access from the instance to `get.k3s.io` and Ubuntu package
  repositories.
- A security group that does not expose the Kubernetes API publicly.
- At least 2 GB RAM is recommended for the later application and observability
  modules; the k3s bootstrap itself is lightweight.

The script does not require AWS credentials and does not configure Argo CD,
Prometheus, Grafana, Docker, or the sample application.

## Execution Flow

1. Require root privileges and start timestamped logging.
2. Verify Ubuntu or Debian compatibility.
3. Update apt metadata and install `ca-certificates` and `curl`.
4. Reuse active k3s, start an existing inactive installation, or install the
   latest stable release using the official k3s installer.
5. Enable and start the `k3s` systemd service.
6. Query the Kubernetes API using the k3s-provided kubectl.
7. Wait for every node to report the `Ready` condition.
8. For the detected EC2 user, create a mode `600` kubeconfig at
   `~/.kube/config`. The credentials remain on the EC2 host and are not sent
   anywhere else.
9. Print node and all-pod status.

## Usage

From the repository, review the script and transfer it to the host during the
controlled deployment phase. Then run:

```bash
chmod +x bootstrap-k3s.sh
sudo ./bootstrap-k3s.sh
```

The script writes a local log to `/var/log/bootstrap-k3s.log`. It is safe to
rerun for the normal completed state: an active k3s service is not blindly
reinstalled.

## Successful Installation

The final output should include:

```text
k3s service is active.
NAME             STATUS   ROLES                  AGE   VERSION
<node-name>      Ready    control-plane,master   ...   v...
...
k3s bootstrap completed successfully.
```

The exact node name, age, and version depend on the EC2 host and the current
k3s release.

## Troubleshooting

- **Not root:** run the script with `sudo`.
- **Unsupported OS:** use the Ubuntu AMI selected by Terraform.
- **Package or installer download failure:** verify outbound HTTPS and DNS,
  then inspect the log and rerun after the network is available.
- **Service failure:** run `sudo systemctl status k3s` and
  `sudo journalctl -u k3s -n 50`.
- **Node does not become Ready:** inspect `sudo k3s kubectl get nodes` and the
  k3s journal; check available memory and disk space.
- **kubectl access as the EC2 user:** reconnect after bootstrap or run
  `kubectl get nodes`; the script installs a private user kubeconfig when an
  `ubuntu` or invoking `sudo` user is available.

## Status

Module 3 automation has been implemented and reviewed locally. Runtime
validation against a real EC2 instance will be performed later during the
controlled end-to-end deployment phase. No AWS resources were created and this
script has not been executed on AWS.
