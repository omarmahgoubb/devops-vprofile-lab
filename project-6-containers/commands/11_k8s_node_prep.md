# kubeadm — prepare a node (run on master, later on each worker)

Same steps on **every** Kubernetes VM. Do **not** run `kubeadm init` on workers.

Why: Kubernetes 1.24+ uses **CRI**, not Docker. We use **containerd** (official kubeadm default). Class CRI-O lab is the same idea, different runtime package. Pin **v1.32** so all three nodes match; `apt-mark hold` stops a surprise upgrade.

## 1. Swap off

kubelet wants predictable RAM. This box already had `Swap: 0B`; still make it permanent.

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
free -h
```

## 2. Kernel modules + forwarding

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables
```

| Piece | Why |
|---|---|
| `overlay` | containerd image layers |
| `br_netfilter` | iptables sees CNI bridge traffic |
| `ip_forward=1` | this node routes pod traffic |

## 3. containerd

```bash
sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd
sudo systemctl status containerd --no-pager
grep -n -i SystemdCgroup /etc/containerd/config.toml
```

`SystemdCgroup = true` must match kubelet (Ubuntu is systemd). Check the grep — `sed` can no-op on containerd 2.x if the key name differs. We had line 109: `SystemdCgroup = true`.

## 4. kubeadm / kubelet / kubectl 1.32

```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubeadm version
kubectl version --client
sudo systemctl enable kubelet
```

| Binary | Job |
|---|---|
| `kubeadm` | `init` / `join` |
| `kubelet` | node agent; healthy only after `init` or `join` |
| `kubectl` | API CLI (needed on master; optional on workers) |

Installed on master: **v1.32.13**. kubelet may flap until `init` — normal.
