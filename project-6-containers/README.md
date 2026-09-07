# DevOps VProfile Lab — Containers (Lecture 6)

Same Java app. Before this lecture it ran **on VMs**. Now each role is a **container**.

Workstation: VirtualBox **ubuntu** (not Vagrant). SSH on Host-Only; Docker Hub needs **NAT** as well.

## Tasks

| Step | What |
|---|---|
| **0** | [docs/network-and-docker.md](docs/network-and-docker.md) — SSH + Docker + internet |
| **1** | [docs/choose-images.md](docs/choose-images.md) — pick / pull base images |
| **2** | [app/](app/) — Tomcat Dockerfile + build |
| **3** | Run the app container; **elinks** (no Chrome in the VM) |
| **4** | Push to Docker Hub |
| **5** | [compose/](compose/) — five services together |
| **5b** | [docs/compose-login.md](docs/compose-login.md) — `GRANT` + MySQL `skip-ssl` so login works |
| **Later** | kubeadm: 3 VMs (1 master, 2 workers), all Ubuntu |

Class Dockerfiles (from the session): [docs/class-dockerfiles.md](docs/class-dockerfiles.md).

## How we test Maven / the app without a database

Maven **does not need** MySQL. It only builds `vprofile-v2.war`.

| What you run | Needs DB? | What you prove |
|---|---|---|
| `mvn install -DskipTests` | No | WAR exists |
| `docker build` | No | Image builds |
| `docker run` app only + elinks `:8080` | No | Tomcat serves the UI |
| Login, accounts, cache | **Yes** | Compose + [login extras](docs/compose-login.md) (`admin` GRANT, MySQL `skip-ssl`) |

Laptop URL is the VM Host-Only IP (`http://192.168.56.123`), not `127.0.0.1`. Web form: `admin_vp` / `admin_vp`.
