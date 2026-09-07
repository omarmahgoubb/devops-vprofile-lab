# awx01 — AWX install (inside the Ubuntu VM)

You are already in the VM (`vagrant ssh awx01`). User is `vagrant`. Run these in order.

## 1. Tools

Install Git and `make` (needed to deploy the AWX operator):

```bash
sudo apt update
sudo apt install -y git make curl ca-certificates gnupg software-properties-common
```

## 2. Docker

Add Docker’s apt repo and install the engine (minikube will run Kubernetes *inside* Docker):

```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

Log out and back in so the `docker` group applies (do not skip this):

```bash
exit
```

On Windows:

```powershell
vagrant ssh awx01
```

Check Docker works **without** sudo:

```bash
docker ps
```

## 3. minikube + kubectl

Download minikube and start a small cluster. Give it 6 GB and leave ~2 GB for Ubuntu itself:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb
minikube start --driver=docker --cpus=2 --memory=6144 --addons=ingress
sudo snap install kubectl --classic
kubectl get nodes
```

`kubectl get nodes` should show one node `Ready`.

## 4. AWX operator

Clone the operator, pin the class version, create namespace `ansible-awx`, deploy:

```bash
git clone https://github.com/ansible/awx-operator.git
cd awx-operator
git checkout 2.19.0
export NAMESPACE=ansible-awx
make deploy
kubectl get pods -n ansible-awx
```

Wait until the operator pod is `Running` (`2/2`).

Operator `2.19.0` still asks for `gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0`. That image was removed, so the pod stays `1/2 ImagePullBackOff`. Point the sidecar at Quay (same tag):

```bash
kubectl set image -n ansible-awx deploy/awx-operator-controller-manager \
  kube-rbac-proxy=quay.io/brancz/kube-rbac-proxy:v0.15.0
kubectl get pods -n ansible-awx
```

You want `READY 2/2` and `STATUS Running`. Then continue.

## 5. AWX instance

From the `awx-operator` folder, copy the demo manifest and set the name to `awx-ubuntu` (class name):

```bash
cp awx-demo.yml awx-ubuntu.yml
```

Replace the file with:

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-ubuntu
spec:
  service_type: nodeport
```

(`nano awx-ubuntu.yml` or copy from `/vagrant/files/awx-ubuntu.yml` — Vagrant shares this project folder at `/vagrant`.)

```bash
cp /vagrant/files/awx-ubuntu.yml .
kubectl create -f awx-ubuntu.yml -n ansible-awx
```

Pods take several minutes. Watch:

```bash
kubectl get pods -n ansible-awx -w
```

`Ctrl+C` when `awx-ubuntu` pods are `Running` (not `Init` / `CrashLoop`).

## 6. Open the UI

Forward AWX to port 8080 on all interfaces (Windows can use http://127.0.0.1:8088 or http://192.168.56.20:8080):

```bash
kubectl port-forward --address 0.0.0.0 svc/awx-ubuntu-service 8080:80 -n ansible-awx
```

Leave that terminal running. Open a **second** SSH (`vagrant ssh awx01` in another window) for the password.

## 7. Admin password

```bash
kubectl get secret awx-ubuntu-admin-password -o jsonpath="{.data.password}" -n ansible-awx | base64 -d; echo
```

Browser: **http://127.0.0.1:8088**  
User: `admin`  
Password: the output of the command above.

**Task 1 is done** when you see the AWX dashboard. Do not add inventories yet (that is Task 2).
