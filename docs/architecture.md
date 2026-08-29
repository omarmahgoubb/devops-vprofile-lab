# Architecture and ports

**Hosts**

- `web01` `192.168.56.11` — Nginx (TCP 80 → upstream `app01:8080`)
- `app01` `192.168.56.12` — Tomcat (TCP 8080)
- `rmq01` `192.168.56.13` — RabbitMQ (TCP 5672)
- `mc01` `192.168.56.14` — Memcached (TCP 11211, UDP 11111)
- `db01` `192.168.56.15` — MariaDB (TCP 3306)
- `nagios` `192.168.56.10` — Nagios Core + Apache (Project 3; HTTP 80, NRPE 5666)

**Flow**

Client → `web01:80` (Nginx) → `app01:8080` (Tomcat) → cache (`mc01:11211`) and DB (`db01:3306`); async work via `rmq01:5672`.

Nagios polls ping from `192.168.56.10` and calls NRPE on each app VM (TCP 5666) for CPU load and RAM.

Bring-up order matches `project-1-manual/commands/` and `project-2-automation/scripts/`: DB → cache → broker → app → web. Project 3 adds Nagios last.
