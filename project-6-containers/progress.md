# Lecture 6 progress

**Status: Lecture 6 done.** Compose on `ubuntu` **and** the same app on a 3-node kubeadm cluster. Laptop kube URL: **http://192.168.56.124:30080/** (`admin_vp` / `admin_vp`).

| Step | Result |
|---|---|
| App image | `omarrmahgoub/vprofile-app:v1` — build, run, elinks `:8080` |
| App on Hub | tagged/pushed as `omarrmahgoub/vprofile-app:v1` |
| DB image | `omarrmahgoub/vprofile-db:v1` (`mysql:5.7.25` + `db_backup.sql`) — on Hub |
| Web image | `omarrmahgoub/vprofile-web:v1` — on Hub |
| Official | `memcached`, `rabbitmq` pulled |
| Compose | five services; laptop **http://192.168.56.123** (`admin_vp` / `admin_vp`) |

Gotcha: Host-Only only → `docker pull` DNS fails. NIC2 NAT + netplan `enp0s8` (`10.0.3.15`). SSH: `192.168.56.123`.

Login extras (page loaded, `/login?error` until these ran): (1) `GRANT` `admin`/`admin123` on `accounts` — official MySQL image does not create that user; (2) MySQL `skip-ssl` — Connector/J 8 vs `mysql:5.7.25` `SSLHandshakeException`. `command: --skip-ssl` is now in [compose/docker-compose.yml](compose/docker-compose.yml). See [docs/compose-login.md](docs/compose-login.md).

**kubeadm (19–20 Sep 2026):** three nodes **Ready**, v1.32.13, containerd. `init --apiserver-advertise-address=192.168.56.124 --pod-network-cidr=10.244.0.0/16` + Flannel. Commands: [10](commands/10_k8s_master_vm.md)–[15](commands/15_k8s_fix_node_ip.md).

**kubeadm deploy:** [k8s/vprofile.yaml](k8s/vprofile.yaml) from Hub (`omarrmahgoub/vprofile-{app,db,web}:v1`). Job `db01-grant` (no `kubectl exec`). Laptop **http://192.168.56.124:30080/** (`admin_vp` / `admin_vp`).

Dual-NIC fixes we actually needed: Flannel `--iface=enp0s3`; kubelet `--node-ip` on master `192.168.56.124`; nginx `resolver 10.96.0.10` + `proxy_redirect` so Spring keeps `:30080`. See [docs/k8s-dual-nic.md](docs/k8s-dual-nic.md). Workers can still show InternalIP `10.0.3.15` until [15](commands/15_k8s_fix_node_ip.md) is run on them.
