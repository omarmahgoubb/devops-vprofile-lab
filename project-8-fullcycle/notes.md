# Personal notes — Lecture 8 (full cycle)

Lecture 7 proved Jenkins can clone Git and Argo CD can sync a YAML file. Neither one rebuilds the Java UI.

This lecture: edit the UI in our own Git repo, and see a new pod.

## Decisions

- Source of the app: `https://github.com/hkhcoder/vprofile-project.git` branch `main`. Copied into a **private** repo, not into `devops-vprofile-lab`.
- Infra tool: **Bicep**. Lecture 4 was already an Azure template. Terraform was the class name. Bicep keeps this task on the cycle instead of a second syntax.
- Cloud: **Azure**. Two VMs only: one control-plane, one worker. Larger than the VirtualBox 2 CPU / 4 GB nodes, which froze under Jenkins.
- VM sizes: master `Standard_B2ms` (2 vCPU, 8 GB RAM, 64 GB OS disk). Worker `Standard_D4s_v5` (4 vCPU, 16 GB RAM, 64 GB OS disk). Master stays NoSchedule. Worker runs Jenkins, the Kaniko/Maven build, Tomcat, MariaDB, Memcached, and RabbitMQ. Burstable B-series is wrong for that build.
- Registry: **ACR Basic** (`<name>.azurecr.io/vprofile-app:<git commit>`). Chosen over Docker Hub. Cost is the tradeoff: the registry bills while it exists. Pull is private, so the cluster needs an image pull secret or AcrPull on the worker. The ACR password stays out of git.
- Azure DevOps is not in the path. Repos would replace GitHub. Pipelines would replace Jenkins. A deploy stage would replace Argo CD. We keep GitHub, Jenkins, and Argo.
- The class `Jenkinsfile` stays in the private repo as `ci-class-Jenkinsfile`. It calls Nexus and Sonar at addresses we do not have.
- Deployed from Cloud Shell on 2026-10-17 after local Azure CLI returned `AADSTS50076` (MFA for Resource Manager). Names: resource group `rg-vprofile-k8s` in `eastus`, not the Lecture 4 group `vprofile`. VNet `vnet-vprofile-k8s` (`10.10.0.0/16`) / `snet-vprofile-k8s` (`10.10.1.0/24`). NSG `nsg-vprofile-k8s` (22, 6443, 30080, 30081, 30082). VMs `vm-vprofile-master` (`Standard_B2ms`) and `vm-vprofile-worker` (`Standard_D4s_v5`), Ubuntu 22.04, 64 GB Standard SSD. NICs `nic-vprofile-master` / `nic-vprofile-worker`. Public IPs `pip-vprofile-master` / `pip-vprofile-worker` are Standard static. Basic dynamic IPs are retired, so these IPs bill until deleted. ACR `acrvprofilel8` Basic, admin user enabled. Admin user `azureuser`. Password is a deploy-time parameter, not a file in git. Live addresses: master `40.87.97.146`, worker `23.100.22.38`, registry `acrvprofilel8.azurecr.io`.

## Cycle (not running yet)

```text
edit login.jsp and push to omarmahgoubb/vprofile
        → GitHub starts Jenkins
        → mvn, image build, push to ACR Basic
        → Jenkins commits the new tag in k8s/app.yaml
        → Argo CD syncs
        → new app pod
```

MariaDB, Memcached, and RabbitMQ still have to be on that cluster or the new pod has no page to show. They are not in `k8s/app.yaml` yet.
