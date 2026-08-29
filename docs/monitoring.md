# Monitoring design (Nagios)

**Server:** `mon01` (Rocky 9) with packages: `nagios`, `nagios-plugins-all`, `nrpe`, and `httpd`.  
**Firewall:** Opens HTTP (80) for the UI and 5666/TCP if NRPE is later enabled on clients.

**Initial services:** Ping checks per host (availability).  
**Recommended extensions:**
- `check_tcp` services for:
  - MySQL (`db01:3306`)
  - Memcached (`mc01:11211`/`UDP 11111`)
  - RabbitMQ (`rmq01:5672`)
  - Tomcat (`app01:8080`)
  - Nginx (`web01:80`)
- Add NRPE to clients for deeper health checks (disk, load, process, app-specific).

**IP mapping:** Clients in `clients.cfg` must match Project 2: `web01=.11`, `app01=.12`, `rmq01=.13`, `mc01=.14`, `db01=.15` on `192.168.56.0/24`. `mon01` is `.16`.
