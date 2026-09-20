# kubeadm on two NICs — Flannel, `--node-ip`, NodePort

Each lab VM has two IPv4 addresses:

| NIC | Typical name | Address | Use |
|---|---|---|---|
| Host-Only | `enp0s3` | `192.168.56.x` (unique per VM) | SSH from Windows, `kubeadm` API, laptop browser |
| NAT | `enp0s8` | `10.0.3.15` (**same on every VM**) | `apt` / image pulls only |

`10.0.3.15` is not a cluster address. If kubelet or Flannel pick it, nodes look `Ready` while `kubectl logs` / `exec` / NodePort from the laptop break.

## 1. Flannel `--iface=enp0s3`

Flannel runs `hostNetwork`. Without `--iface` it binds the first default route — NAT. Overlay traffic then uses `10.0.3.15` on every node.

After the upstream `kube-flannel.yml` apply:

```bash
kubectl -n kube-flannel patch ds kube-flannel-ds --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--iface=enp0s3"}
]'
kubectl -n kube-flannel rollout status ds/kube-flannel-ds
```

Confirm the arg:

```bash
kubectl -n kube-flannel get ds kube-flannel-ds -o jsonpath='{.spec.template.spec.containers[0].args}' ; echo
```

You want `--ip-masq --kube-subnet-mgr --iface=enp0s3`.

## 2. kubelet `--node-ip` (Host-Only)

`kubectl get nodes -o wide` **InternalIP** is what the API uses to reach kubelet (logs, exec, some kube-proxy paths).

Default on this lab: `10.0.3.15` for every node. Fix is in [commands/15_k8s_fix_node_ip.md](../commands/15_k8s_fix_node_ip.md) — write `/var/lib/kubelet/kubeadm-flags.env` with `--node-ip=$(enp0s3)` and `systemctl restart kubelet`.

Done when InternalIPs are three different `192.168.56.x` values. Master was set to `192.168.56.124`. Run the same block on **worker1** and **worker2** if they still show `10.0.3.15`.

Until that is set, `kubectl logs` / `exec` often say `pods/log` NotFound or `pod does not exist`. Use a Job (or `crictl` on the worker) instead.

## 3. Laptop URL is NodePort 30080

`web01` Service is **NodePort 30080** → nginx in the pod on **80**. Nothing listens on the VM’s host port 80.

Laptop: **http://192.168.56.124:30080/** (`admin_vp` / `admin_vp`).

Spring sends `Location: http://192.168.56.124/login` (port 80 omitted). Chrome then shows `ERR_CONNECTION_REFUSED`. Nginx `proxy_redirect` in [k8s/vprofile.yaml](../k8s/vprofile.yaml) rewrites that to `:30080` so login stays on NodePort. `$http_host` alone is not enough.

Keep `:30080` in the address bar. If a redirect drops it, open **http://192.168.56.124:30080/login**.
