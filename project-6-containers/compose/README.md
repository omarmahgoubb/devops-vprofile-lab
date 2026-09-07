# Step 5 — Compose (all five roles)

On the ubuntu VM, after the images exist (`omarrmahgoub/vprofile-app:v1`, `…-db:v1`, `…-web:v1`, plus `memcached` and `rabbitmq`):

```bash
cd ~/vprofile-docker/compose
docker compose up -d
docker compose ps
```

[docker-compose.yml](docker-compose.yml) already has `command: --skip-ssl` under `db01` so login survives a recreate. After the first `up` on a **new** volume, still `GRANT` the JDBC user — see [docs/compose-login.md](../docs/compose-login.md).

| From | URL |
|---|---|
| VM (elinks) | `http://127.0.0.1` |
| Laptop browser | `http://192.168.56.123` (Host-Only IP of the VM, **not** `127.0.0.1`) |

App login: **`admin_vp` / `admin_vp`**.

Do **not** mount a volume on Tomcat `webapps` (class `appdata`). It hides `ROOT.war`. Keep `dbdata` on MySQL only.
