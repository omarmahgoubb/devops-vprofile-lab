# 03 — kubeadm node prep (done on both VMs)

SSH works: master `40.87.97.146`, worker `23.100.22.38`, user `azureuser`.

Run the same block on **both** VMs. These Azure VMs have one NIC, so the VirtualBox dual-NIC fixes are not part of prep. Do **not** run `kubeadm init` or `kubeadm join` in this step.

Kubernetes 1.32 matches Lecture 6. containerd is the runtime. Swap must stay off or kubelet will refuse to start.

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
free -h

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

sudo apt update
sudo apt install -y containerd apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd
grep -n SystemdCgroup /etc/containerd/config.toml

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet
kubeadm version
hostname -I
```

`SystemdCgroup = true` must appear in the grep. `free -h` must show swap `0B`. kubelet may restart until `init` or `join`. That is normal.

Done on both VMs. kubeadm **v1.32.13**. containerd **2.2.1**. `SystemdCgroup = true` at line 109. Swap `0B`. A few `sysctl` keys printed `Invalid argument` (`accept_source_route`, `promote_secondaries`). Those keys are not on this kernel. `k8s.conf` still applied `ip_forward=1`.

| VM | Private IP |
|---|---|
| `vm-vprofile-master` | `10.10.1.4` |
| `vm-vprofile-worker` | `10.10.1.5` |
