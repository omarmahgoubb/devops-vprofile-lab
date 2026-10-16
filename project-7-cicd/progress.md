# Lecture 7 progress

**Status: Jenkins job `vprofile-ci` finished SUCCESS (checkout + list `k8s/`). No image build yet. `ubuntu` stays off.**

| Step | Result |
|---|---|
| Plan | Jenkins (`Jenkinsfile`) + Argo CD. GitHub Actions later. No Java changes. |
| VMs powered on | `k8s-master`, `k8s-worker1`, `k8s-worker2`. `ubuntu` left off. |
| Cluster after shutdown | Workers `NotReady` until swap was turned off and `--node-ip` set. Then containerd on worker1 wedged; restart fixed it. App login works again on `:30080`. |
| Argo CD | Namespace `argocd`, upstream install manifest. Server pod `Running` on worker2. Service patched to NodePort **30081**. |
| Plain HTTP | `server.insecure=true`, then `kubectl -n argocd rollout restart deploy/argocd-server`. Laptop **http://192.168.56.124:30081** shows Argo CD 3.5.5, signed in, empty Applications page. |
| Argo Application | Created, then **Sync** with Prune off. Status became **Synced**. Laptop **http://192.168.56.124:30080/** still opens. Git folder `project-6-containers/k8s` is now what Argo deploys. |
| Jenkins | UI **http://192.168.56.124:30082** (2.541.3) on `k8s-worker2`. Job `vprofile-ci` **SUCCESS**: cloned `main` at `af15e0e`, listed `project-6-containers/k8s/vprofile.yaml`, printed `CI reached the deploy folder`. That commit is Project 6 only. Lecture 7 files are not on GitHub yet. |

Details: [commands/01_cluster_after_shutdown.md](commands/01_cluster_after_shutdown.md), [commands/02_argocd_install.md](commands/02_argocd_install.md).
