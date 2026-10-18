# DevOps VProfile Lab — Full cycle (Lecture 8)

A login-page edit became a new pod. Jenkins built the image and pushed it to ACR. Path 1 deployed it with Argo CD. Path 2 deployed it with `kubectl` after the Argo application was removed. Grafana on the same cluster shows one Lab overview page. The last login design is the cream and blue split page, commit `57ff559`.

| Piece | Where it lives |
|---|---|
| Java, Dockerfile, `Jenkinsfile`, `k8s/app.yaml` | Private repo [omarmahgoubb/vprofile](https://github.com/omarmahgoubb/vprofile) |
| Two Azure VMs (master + worker) | **Deployed** in `rg-vprofile-k8s`. Master `40.87.97.146` (`Standard_B2ms`). Worker `23.100.22.38` (`Standard_D4s_v5`). User `azureuser`. |
| Build and image push | Jenkins on the cluster, to **ACR Basic** |
| Deploy | Path 1: Argo CD. Path 2: Jenkins `kubectl set image`. |

## Tasks

| Step | What | State |
|---|---|---|
| **1** | Private repo from the class Java project | Done. [commands/01_private_repo.md](commands/01_private_repo.md) |
| **2** | Bicep: resource group, VNet, NSG, two VMs, ACR | Deployed. [commands/02_bicep.md](commands/02_bicep.md) |
| **3** | kubeadm, then Argo CD and Jenkins | Done. Cluster Ready. Argo app `vprofile` is Synced. |
| **4** | Jenkins controller, then image push to ACR | Done. [commands/08_jenkins_pipeline.md](commands/08_jenkins_pipeline.md) |
| **5** | Edit `login.jsp`, push, new pod | Done. Last design is commit `57ff559`. |
| **6** | Path 1 webhook plus Argo, then Path 2 `kubectl` | Done. [commands/09_path1_auto.md](commands/09_path1_auto.md), [commands/10_path2_kubectl.md](commands/10_path2_kubectl.md) |
| **7** | Prometheus and Grafana, one Lab overview page | Done. [commands/11_monitoring.md](commands/11_monitoring.md) |

Visible edit that shipped: `src/main/webapp/WEB-INF/views/login.jsp` (`welcome omar`, `mahgoub`).

Registry is **ACR Basic**. It bills about $5 per month while the registry exists, even with one image and even when both VMs are deallocated. Delete the registry to stop that charge. Do not use Standard, Premium, or geo-replication. A deallocated VM is not billed for compute. Its disk still is. The public IPs are Standard and static, because Basic dynamic IPs are retired, so those IPs also bill until deleted. ACR is private, so the worker needs a pull secret or an AcrPull identity before the pod can start.
