# Lecture 6 progress

**Status: compose stack works** on VirtualBox `ubuntu`. Host-Only + NAT.

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

**Not done yet:** kubeadm cluster (3 Ubuntu VMs: 1 master + 2 workers).
