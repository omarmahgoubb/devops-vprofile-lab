# Step 5 — Compose (all five roles)

Service names **must** be `db01` `mc01` `rmq01` `app01` `web01` (hostnames inside the WAR).

```bash
mkdir -p ~/vprofile-docker/compose
cd ~/vprofile-docker/compose
```

`vim docker-compose.yml` — use [compose/docker-compose.yml](../compose/docker-compose.yml) (`command: --skip-ssl` under `db01`). Do **not** mount a volume on Tomcat `webapps`.

```bash
docker compose up -d
docker compose ps
elinks http://127.0.0.1
```

From the laptop browser (not `127.0.0.1`):

**http://192.168.56.123**

A `version:` warning is harmless. The page can load while login still fails — do [05_login.md](05_login.md).
