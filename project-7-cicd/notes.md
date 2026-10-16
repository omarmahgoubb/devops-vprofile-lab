# Personal notes — Lecture 7 (CI/CD)

Lecture 6 path: VMs → Docker Compose → kubeadm + `k8s/vprofile.yaml`.  
Lecture 7 path: a git change should build and deploy that same app. We do not edit the Java app.

## Jenkins vs Argo CD

- **Argo CD** = deploy only. It applies Dockerfile / Compose / Kubernetes YAML that is already in Git. It does not run Maven or `docker build`.
- **Jenkins** = CI and CD. For this full stack we need Jenkins (or GitHub Actions) to **build** `vprofile-app` and change the image tag. Argo then sees that commit and rolls the cluster.
- One static web app whose image never changes can be Argo alone. Our five roles need a CI tool because the app image is built.

Two Jenkins styles: Freestyle (GUI, one job per phase) and **Pipeline as code** (`Jenkinsfile`). We use the `Jenkinsfile`.

## Where things run

| VM | IP | Now |
|---|---|---|
| `k8s-master` | `192.168.56.124` | Argo CD API traffic, NodePorts |
| `k8s-worker1` | `192.168.56.127` | vprofile pods (MySQL, Tomcat, RabbitMQ, Memcached, nginx) |
| `k8s-worker2` | `192.168.56.128` | `argocd-server`, and the Jenkins controller (kept off worker1) |
| `ubuntu` | `192.168.56.123` | stays **off**. 12 GB / 3 CPU on top of the three 4 GB nodes is too much. Jenkins is a pod instead |

Host-Only addresses did **not** change after the VMs were off for weeks. Kubernetes had been advertising NAT `10.0.3.15` on the workers because `--node-ip` was never set there.
