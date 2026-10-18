# 11 — Prometheus and Grafana on the same cluster

The vprofile image, Jenkins, and ACR flow stay as they are. Prometheus collects CPU, memory, restarts, and pod status. Grafana shows those graphs. The Java app is not changed, so login counts are not in the graphs.

Grafana is NodePort `30083`. Prometheus is only inside the cluster. History is kept for 6 hours in memory and on the node disk, capped at 2 GB. No extra Azure disk.

The control-plane scrape jobs are off. On kubeadm those ports listen on localhost only, so the targets would look down. Node, pod, and workload graphs still work.

The Grafana password is typed in the Helm command on the master. It is not written in this file.

## 1. Open port 30083

From Azure Cloud Shell. The prompt there is PowerShell, so paste this as one line. A trailing `\` does not continue the command.

```powershell
az network nsg rule create --resource-group rg-vprofile-k8s --nsg-name nsg-vprofile-k8s --name allow-nodeport-grafana --priority 1050 --access Allow --protocol Tcp --direction Inbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 30083
```

## 2. Install on the master

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
```

Then the values file and `helm install` from the live session. Pods should land on the worker. The master stays tainted.

## 3. Open Grafana

`http://40.87.97.146:30083`

User `admin`. The page to use is **Lab overview** at `http://40.87.97.146:30083/d/lab-overview/lab-overview`. It has the two nodes, pods running, pods not running, restarts, worker RAM, the pods that restarted, and the five apps with RAM, limit, and start time. The stock Kubernetes dashboards are turned off with `defaultDashboardsEnabled: false`.

Installed Sun Oct 18 2026. Release `kps`, namespace `monitoring`. All pods reached Ready, including Grafana `3/3` and Prometheus `2/2`. `http://40.87.97.146:30083/login` returned 200.
