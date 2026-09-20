# DevOps VProfile Lab — Containers (Lecture 6)

Same Java app. Before this lecture it ran **on VMs**. Now each role is a **container**.

Workstation: VirtualBox **ubuntu** (not Vagrant). SSH on Host-Only; Docker Hub needs **NAT** as well.

## Tasks

| Step | What | Commands we typed |
|---|---|---|
| **0** | [docs/network-and-docker.md](docs/network-and-docker.md) — SSH + Docker + internet | [commands/00_network.md](commands/00_network.md) |
| **1** | [docs/choose-images.md](docs/choose-images.md) — pick / pull base images | pull is in `00` / `03` |
| **2–3** | [app/](app/) — Tomcat Dockerfile, `docker run`, elinks | [commands/01_app.md](commands/01_app.md) |
| **4** | Push app to Docker Hub | [commands/02_push_app.md](commands/02_push_app.md) |
| **5** | [compose/](compose/) — five services | [commands/03_db_web.md](commands/03_db_web.md), [04_compose.md](commands/04_compose.md) |
| **5b** | [docs/compose-login.md](docs/compose-login.md) — GRANT + `skip-ssl` | [commands/05_login.md](commands/05_login.md) |
| **5c** | Push db + web images | [commands/06_push_db_web.md](commands/06_push_db_web.md) |
| **6** | kubeadm master VM + node prep + `init` + Flannel | [10](commands/10_k8s_master_vm.md), [11](commands/11_k8s_node_prep.md), [12](commands/12_k8s_init_flannel.md) |
| **7** | Worker VMs + `kubeadm join` | [13](commands/13_k8s_worker.md) — three nodes **Ready** |
| **8** | Deploy vprofile (Hub images) | [14](commands/14_k8s_deploy.md), [k8s/vprofile.yaml](k8s/vprofile.yaml) |
| **8b** | Dual-NIC: Flannel `--iface`, kubelet `--node-ip`, nginx `proxy_redirect` | [15](commands/15_k8s_fix_node_ip.md), [docs/k8s-dual-nic.md](docs/k8s-dual-nic.md) |

Class Dockerfiles (from the session): [docs/class-dockerfiles.md](docs/class-dockerfiles.md).

## How we test Maven / the app without a database

Maven **does not need** MySQL. It only builds `vprofile-v2.war`.

| What you run | Needs DB? | What you prove |
|---|---|---|
| `mvn install -DskipTests` | No | WAR exists |
| `docker build` | No | Image builds |
| `docker run` app only + elinks `:8080` | No | Tomcat serves the UI |
| Login, accounts, cache | **Yes** | Compose + [login extras](docs/compose-login.md) (`admin` GRANT, MySQL `skip-ssl`) |

Laptop Compose URL: Host-Only `http://192.168.56.123` (not `127.0.0.1`).  
Laptop kubeadm URL: **http://192.168.56.124:30080/** (NodePort; keep `:30080`).  
Web form: `admin_vp` / `admin_vp`.
