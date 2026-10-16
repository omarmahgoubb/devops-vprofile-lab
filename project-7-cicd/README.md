# DevOps VProfile Lab — CI/CD (Lecture 7)

Lecture 6 ran the same app with Compose, then with a 3-node kubeadm cluster. Lecture 7 adds **CI/CD**.

| Tool | Role in this lab |
|---|---|
| **Argo CD** | Continuous **deployment** only. Watches Git (Kubernetes YAML) and makes the cluster match it. Does not compile, test, or push images. |
| **Jenkins** | **CI/CD**. `Jenkinsfile` (pipeline as code): Maven, image build, push to Docker Hub, then change the image tag in Git. |
| **GitHub Actions** | Extra, same CI idea as Jenkins. Not started. |

Cloud options we are **not** building: AWS CodePipeline, Azure DevOps, GitLab CI. Freestyle Jenkins jobs (one GUI job per phase) are mentioned only. We use a **Jenkinsfile**.

Argo CD and Jenkins both run **on the Lecture 6 kubeadm cluster**. The 12 GB `ubuntu` VM stays off so the laptop is not running four heavy VMs. These nodes use containerd, so the later image build uses Kaniko inside the cluster instead of `docker build` on `ubuntu`.

## Tasks

| Step | What | Commands |
|---|---|---|
| **1** | Bring the kubeadm cluster back after a long shutdown | [commands/01_cluster_after_shutdown.md](commands/01_cluster_after_shutdown.md) |
| **2** | Install Argo CD, NodePort **30081** | [commands/02_argocd_install.md](commands/02_argocd_install.md) |
| **3** | Argo CD Application → Git `k8s/vprofile.yaml` | [commands/02_argocd_install.md](commands/02_argocd_install.md) — **Synced** |
| **4** | Jenkins controller on worker2, NodePort **30082** | [commands/03_jenkins_install.md](commands/03_jenkins_install.md), [k8s/jenkins.yaml](k8s/jenkins.yaml) |
| **4b** | First pipeline: checkout Git, list `k8s/` | [commands/04_jenkins_pipeline.md](commands/04_jenkins_pipeline.md), [Jenkinsfile](Jenkinsfile) |
| **5** | GitHub Actions (extra) | not started |

App (unchanged): **http://192.168.56.124:30080/** (`admin_vp` / `admin_vp`). Keep `:30080`.

Argo CD UI: **http://192.168.56.124:30081** user `admin`. Password is **not** stored in git. Read it from the cluster secret (command in [02](commands/02_argocd_install.md)). The UI loaded on 16 Oct 2026 (v3.5.5, no applications yet).

Git Argo will watch: `https://github.com/omarmahgoubb/devops-vprofile-lab.git`, branch `main`, path `project-6-containers/k8s`.
