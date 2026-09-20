# Personal notes — Lecture 6 (containers)

Host-based (Vagrant / Azure VMs / Ansible) → **container-based**.

Controller/workstation: VirtualBox VM **ubuntu** (12 GB, 3 CPU, 40 GB disk).
- NIC1: Host-Only → SSH from Windows (`192.168.56.x`)
- NIC2: NAT → internet / Docker Hub (without this, `docker pull` fails DNS)

## Path (class)

1. Pick images (official vs our Dockerfile)
2. Dockerfile + `docker build`
3. Test (`docker run`, **elinks** in the terminal)
4. Push to Docker Hub
5. `docker compose` (all five roles)
6. kubeadm: 3 Ubuntu VMs **Ready** (`k8s-master` `192.168.56.124`, `k8s-worker1`, `k8s-worker2`).
7. Deploy the same Hub images with [k8s/vprofile.yaml](k8s/vprofile.yaml). Laptop: **http://192.168.56.124:30080/** (`admin_vp` / `admin_vp`).

## Images

| Role | Image | Notes |
|---|---|---|
| App | `tomcat:8-jre11` + our WAR | No ready “vprofile” image |
| DB | `mysql:5.7.25` + `db_backup.sql` | Class SQL Dockerfile |
| Nginx | `nginx` + site conf | Pull latest, we add conf |
| Memcached | `memcached` | Pull latest |
| RabbitMQ | `rabbitmq` | Pull latest; app needs **5672** |

## Test without DB

- **Maven** only compiles the WAR. It does not start MariaDB.
- **`docker run` the app alone:** Tomcat comes up. elinks can open `:8080`. Login / cache / queue **fail** until compose (or kube) starts db / mc / rmq.
- **Full test:** `docker compose up` with all services.
- After first `up`, login needs extras: `GRANT` for JDBC `admin`, and MySQL `skip-ssl` (see [docs/compose-login.md](docs/compose-login.md)).
- Laptop: `http://192.168.56.123` — form user `admin_vp` / `admin_vp`.

## kubeadm

- Runtime: **containerd** (not Docker; class CRI-O is the same idea).
- Kubernetes **1.32** held with `apt-mark hold`.
- Advertise Host-Only IP on `init` (not NAT `10.0.3.15`).
- Pod CIDR `10.244.0.0/16` + Flannel (Calico default overlaps `192.168.56.0/24`).
- Dual NIC: Flannel `--iface=enp0s3`; kubelet `--node-ip` = Host-Only ([docs/k8s-dual-nic.md](docs/k8s-dual-nic.md), [commands/15_k8s_fix_node_ip.md](commands/15_k8s_fix_node_ip.md)). Master InternalIP is `192.168.56.124`. Run the same `--node-ip` block on workers if they still show `10.0.3.15`.
- Nginx: `resolver 10.96.0.10` (not the `kube-dns` hostname). `proxy_redirect` rewrites Spring `Location` to `:30080`.
- GRANT is Job `db01-grant` in the YAML (do not rely on `kubectl exec` until `--node-ip` is Host-Only).
- Commands we typed: `commands/10_*.md` … `15_*.md`.
- Laptop kube: **http://192.168.56.124:30080/** — keep the port.
