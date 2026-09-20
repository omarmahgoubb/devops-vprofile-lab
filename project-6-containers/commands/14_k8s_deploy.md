# kubeadm — deploy vprofile (same five roles as Compose)

Cluster must show three `Ready` nodes. Work on **`k8s-master`**.

Compose used names `db01` `mc01` `rmq01` `app01` `web01`. The WAR still looks those up. In Kubernetes a **Service** is DNS: `db01.vprofile.svc.cluster.local` (short name `db01` inside the namespace).

| Compose | Kubernetes |
|---|---|
| `image:` | Deployment `spec.template.spec.containers[].image` (Hub) |
| service name | Service `metadata.name` |
| `ports:` | Service port + containerPort |
| `command: --skip-ssl` | container `args: ["--skip-ssl"]` |
| `dbdata` volume | `emptyDir` for the lab (gone if the DB pod is deleted) |
| host port 80 | Service **NodePort 30080** (laptop → any node IP) |

Master stays tainted: app pods land on **workers**.

## Create the file on the master

Copy [k8s/vprofile.yaml](../k8s/vprofile.yaml) to the master (MobaXterm drag-drop, or paste into `cat`). No vim required:

```bash
mkdir -p ~/vprofile-k8s
cat > ~/vprofile-k8s/vprofile.yaml
```

Paste the YAML, then `Ctrl+D` to end. `cat ~/vprofile-k8s/vprofile.yaml | head` to check.

```bash
kubectl apply -f ~/vprofile-k8s/vprofile.yaml
kubectl get pods -n vprofile -o wide
kubectl get svc -n vprofile
```

Wait until all five pods are `Running`. Image pulls from Hub can take a few minutes. `app01` may `CrashLoop` once until MySQL is ready — it should recover.

## Login extras

`MYSQL_USER=admin` is already on the DB Deployment (creates `admin` on first empty `emptyDir`). Job **`db01-grant`** in the YAML waits for MySQL and runs `GRANT` so you do not `kubectl exec`.

```bash
kubectl apply -f ~/vprofile-k8s/vprofile.yaml
kubectl get job -n vprofile
kubectl get pods -n vprofile
```

Job `Complete` = GRANT done. Do **not** rely on `kubectl exec` / `kubectl logs` until kubelet `--node-ip` is Host-Only ([15](15_k8s_fix_node_ip.md)). Those APIs talk to kubelet on `InternalIP`; NAT `10.0.3.15` makes exec say `pod does not exist`.

## From the laptop

NodePort is on **every** node (kube-proxy). Master Host-Only:

**http://192.168.56.124:30080/**

User `admin_vp` / `admin_vp`. **Keep `:30080`.** Spring otherwise redirects to port 80 (`ERR_CONNECTION_REFUSED`). The YAML `proxy_redirect` rewrites `Location` to `:30080`. If Chrome still drops the port, open **http://192.168.56.124:30080/login**.

If the page fails: `kubectl get pods -n vprofile`. For logs, set `--node-ip` first or use `crictl logs` on the worker. Dual-NIC story: [docs/k8s-dual-nic.md](../docs/k8s-dual-nic.md).

## `web01` CrashLoop: `host not found in upstream "app01:8080"`

The image’s `vproapp.conf` has `server app01:8080`. Nginx resolves that **once at start**. Compose DNS made `app01` work. Kubernetes short names often fail that lookup, so nginx exits.

Fix (no image rebuild): ConfigMap with FQDN `app01.vprofile.svc.cluster.local` and resolver **`10.96.0.10`** (CoreDNS ClusterIP — not the `kube-dns` hostname; that failed too), mounted over `/etc/nginx/conf.d/vproapp.conf`. Already in [k8s/vprofile.yaml](../k8s/vprofile.yaml).

On the worker, `crictl logs <id>` if `kubectl logs` returns `pods/log` NotFound.
