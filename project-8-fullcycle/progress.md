# Lecture 8 progress

**Status: the full cycle worked. A login-page edit was built by Jenkins, pushed to ACR, synced by Argo CD, and shown by a new pod.**

| Step | Result |
|---|---|
| Plan | UI edit → Jenkins → ACR Basic → tag in `k8s/app.yaml` → Argo CD → new pod. Two Azure VMs. Bicep. ACR chosen; it bills while the registry exists. |
| Private repo | **https://github.com/omarmahgoubb/vprofile** `main`. Java from hkhcoder, plus `Dockerfile`, `k8s/app.yaml`, `Jenkinsfile`. |
| Bicep | Deployed from Cloud Shell. [commands/02_bicep.md](commands/02_bicep.md) |
| Azure | `rg-vprofile-k8s` in `eastus`. Master `40.87.97.146`. Worker `23.100.22.38`. ACR `acrvprofilel8.azurecr.io`. User `azureuser`. |
| SSH | Both VMs accept `azureuser`. |
| kubeadm prep | Done on both. v1.32.13. Master `10.10.1.4`. Worker `10.10.1.5`. [commands/03_kubeadm_prep.md](commands/03_kubeadm_prep.md) |
| kubeadm | Both nodes Ready, v1.32.13. Master `control-plane`. Worker has no role taint. [commands/04_kubeadm_init.md](commands/04_kubeadm_init.md) |
| Argo CD | Application `vprofile` is Healthy / Synced. `k8s/data.yaml` (`1879645`) added `db01`, `mc01`, `rmq01`. Login worked at `:30080` with no app restart. [commands/06_argocd_app.md](commands/06_argocd_app.md) |
| Jenkins | Build succeeded. Image `acrvprofilel8.azurecr.io/vprofile-app:7198874f1e633a28e7f91fd723a37c17890ceda0` is committed in `k8s/app.yaml` (`3fab761`). Argo sync is next. [commands/08_jenkins_pipeline.md](commands/08_jenkins_pipeline.md) |
| Proof edit | Done. `login.jsp` shows `welcome omar` and navbar brand `mahgoub` at `http://40.87.97.146:30080` after Jenkins and an Argo sync. |
| Path 1 | Done. Webhook built `46bfa43`, Jenkins tagged `7423cb0`, Argo rolled `app01-db7487bd7-442bl`. Page shows a red navbar and `welcome omar`. No Build Now and no Sync click. [commands/09_path1_auto.md](commands/09_path1_auto.md) |
| Path 2 | Done. Jenkins pushed the image to ACR and `kubectl set image` rolled the new pod. Commit `982ad1a` reached the site with no Argo CD sync: dark page, green bar, rounded card, `welcome omar`. [commands/10_path2_kubectl.md](commands/10_path2_kubectl.md) |
| Monitoring | Installed. `kube-prometheus-stack` release `kps` in namespace `monitoring`. Grafana, Prometheus, Alertmanager, both node-exporters, and kube-state-metrics are Running. Grafana NodePort `30083`. No change to the Java app. [commands/11_monitoring.md](commands/11_monitoring.md) |

Details: [commands/01_private_repo.md](commands/01_private_repo.md).
