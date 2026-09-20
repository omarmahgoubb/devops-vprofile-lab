# kubeadm — Flannel `--iface` + kubelet `--node-ip` (no vim)

Dual-NIC background: [docs/k8s-dual-nic.md](../docs/k8s-dual-nic.md).

## Flannel on Host-Only (`enp0s3`) — master

```bash
kubectl -n kube-flannel patch ds kube-flannel-ds --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--iface=enp0s3"}
]'
kubectl -n kube-flannel rollout status ds/kube-flannel-ds
kubectl -n kube-flannel get ds kube-flannel-ds -o jsonpath='{.spec.template.spec.containers[0].args}' ; echo
```

If you already patched once, a second `add` fails. That is OK — check the args line instead.

## `--node-ip` — every node (master, worker1, worker2)

Fills in **this** VM’s `enp0s3` address. Paste the same block on each SSH session.

```bash
IP=$(ip -4 -o addr show enp0s3 | awk '{print $4}' | cut -d/ -f1)
echo "node-ip will be $IP"
sudo tee /var/lib/kubelet/kubeadm-flags.env >/dev/null <<EOF
KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10 --node-ip=${IP}"
EOF
sudo cat /var/lib/kubelet/kubeadm-flags.env
sudo systemctl restart kubelet
```

On master after each node:

```bash
kubectl get nodes -o wide
```

Want three different InternalIPs (`192.168.56.124`, worker1, worker2). Not `10.0.3.15`.

## Live (20 Sep 2026)

| Node | InternalIP after fix | Notes |
|---|---|---|
| `k8s-master` | `192.168.56.124` | done |
| `k8s-worker1` | still `10.0.3.15` until the block above | Host-Only was `192.168.56.127` at install |
| `k8s-worker2` | still `10.0.3.15` until the block above | confirm `enp0s3` first |

Laptop login worked via **master** NodePort after master’s `--node-ip` + Flannel `--iface`. Workers should still get `--node-ip` so logs/exec and worker NodePorts stay correct.
