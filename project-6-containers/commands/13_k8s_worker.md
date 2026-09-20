# kubeadm — worker VM + join

Create `k8s-worker1` / `k8s-worker2` like the master (2 CPU, 4096 MB, 20–25 GB, Host-Only + NAT, Ubuntu 24.04 Server). **Unattended install failed once** — use the manual installer (no microk8s snap).

On the worker, run [11_k8s_node_prep.md](11_k8s_node_prep.md) (same as master). **Never** `kubeadm init` on a worker.

Join (token from master’s `init`; lasts ~24h):

```bash
sudo kubeadm join 192.168.56.124:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

New token if expired (run on **master**):

```bash
kubeadm token create --print-join-command
```

Check on **master**:

```bash
kubectl get nodes
kubectl get pods -n kube-flannel
```

Both node names should be `Ready`. Flannel DaemonSet = one pod per node.

Worker1 Host-Only during install was `192.168.56.127` (confirm with `ip -4 addr` after boot).

## Live check (19 Sep 2026)

```text
k8s-master    Ready   control-plane   v1.32.13
k8s-worker1   Ready   <none>          v1.32.13
k8s-worker2   Ready   <none>          v1.32.13
```

Three Flannel pods `Running`. Worker2 was `NotReady` / Flannel `Init:1/2` for a few minutes (image pull), then `Ready`.

Unattended install failed on worker1 once — use the **manual** Ubuntu installer for workers.

API / join: `192.168.56.124:6443`.

Flannel on `hostNetwork` will show NAT `10.0.3.15` until you add `--iface=enp0s3`. kubelet InternalIP is also `10.0.3.15` until `--node-ip` is the Host-Only address. That is **not** OK for logs/exec/NodePort — do [15](15_k8s_fix_node_ip.md).
