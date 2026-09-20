# kubeadm — `init` + Flannel (master only)

## `kubeadm init`

Advertise the **Host-Only** IP so workers can reach the API. Pod CIDR must match Flannel and must **not** overlap `192.168.56.0/24` or `10.0.3.0/24`.

```bash
sudo kubeadm init \
  --apiserver-advertise-address=192.168.56.124 \
  --pod-network-cidr=10.244.0.0/16
```

| Flag | Why |
|---|---|
| `--apiserver-advertise-address=192.168.56.124` | Workers join this IP:6443. NAT `10.0.3.15` is not reachable from other VMs. |
| `--pod-network-cidr=10.244.0.0/16` | Flannel default. Calico’s `192.168.0.0/16` would overlap Host-Only. |

Save the printed `kubeadm join ...` block. Token lasts ~24 hours. To print it again:

```bash
kubeadm token create --print-join-command
```

(Do not commit a live join token to git.)

`pause` sandbox warning is OK if `init` still succeeds. “remote version v1.37, falling back to stable-1.32” means we stayed on the version we installed.

## kubectl as your user

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config
kubectl get nodes
```

Expect **`NotReady`** until CNI exists.

## Flannel

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl get nodes
kubectl get pods -n kube-system -o wide
kubectl get pods -n kube-flannel -o wide
```

Done when `k8s-master` is **`Ready`** and CoreDNS is `Running` on `10.244.0.x`. Flannel pods live in namespace `kube-flannel`, not `kube-system`.

Control-plane taint `NoSchedule` stays. App pods go on **workers**.

## Flannel must use Host-Only (`enp0s3`)

Default Flannel follows NAT (`10.0.3.15`, same on every VM). NodePort / pod routing from the laptop then fails. Patch after the apply (commands: [15](15_k8s_fix_node_ip.md), why: [docs/k8s-dual-nic.md](../docs/k8s-dual-nic.md)):

```bash
kubectl -n kube-flannel patch ds kube-flannel-ds --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--iface=enp0s3"}
]'
```

## Live inventory (19 Sep 2026)

| Node | Role | Host-Only | Kubernetes |
|---|---|---|---|
| `k8s-master` | control plane | `192.168.56.124` | v1.32.13, `Ready` |

SSH (MobaXterm): `mahgoub@192.168.56.124`.
