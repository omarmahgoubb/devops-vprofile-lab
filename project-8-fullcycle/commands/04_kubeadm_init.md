# 04 — kubeadm init (control plane is up)

Master private IP `10.10.1.4`. Worker private IP `10.10.1.5`. Pod CIDR `10.244.0.0/16` does not overlap the VNet `10.10.0.0/16`.

`--apiserver-advertise-address` is the private IP so the worker joins inside the VNet. `--apiserver-cert-extra-sans` adds the master public IP so a laptop can call the API on `40.87.97.146:6443` later. Do not run this on the worker.

```bash
sudo kubeadm init \
  --apiserver-advertise-address=10.10.1.4 \
  --apiserver-cert-extra-sans=40.87.97.146 \
  --pod-network-cidr=10.244.0.0/16
```

Save the `kubeadm join` line. Do not commit the token.

Then, still on the master:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl get nodes
```

`kubeadm init` succeeded on `vm-vprofile-master` with Kubernetes v1.32.13. The API certificate includes `10.10.1.4` and `40.87.97.146`. The node is tainted `control-plane:NoSchedule`. The pause-image warning is the same one as Lecture 6. The join token is not written here.

Flannel was applied and the worker joined. Both nodes are `Ready` on v1.32.13. One NIC, so no `--iface` patch was needed.