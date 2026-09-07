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
6. Later: kubeadm cluster (3 Ubuntu VMs: 1 master + 2 workers)

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
