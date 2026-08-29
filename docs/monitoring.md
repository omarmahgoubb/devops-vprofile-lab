# Monitoring design (Nagios)

**Server:** `nagios` (CentOS Stream 9, `192.168.56.10`, 1024 MB) with `nagios`, `nagios-plugins-all` (often skipped), **`nagios-plugins-nrpe`**, `nrpe`, and `httpd`.  
**UI:** `http://192.168.56.10/nagios` — user `nagiosadmin` (lab password `admin123`).  
**Firewall:** HTTP (80) for the UI; 5666/TCP for NRPE.

**Clients:** each of `db01`, `mc01`, `rmq01`, `app01`, `web01` runs NRPE (`allowed_hosts=127.0.0.1,192.168.56.10`) and opens **5666/tcp**.

| Check | Plugin | Where it runs |
|---|---|---|
| Ping | `check_ping` | Nagios server (no agent) |
| CPU | `check_load` via `check_nrpe!check_load` | Client NRPE |
| RAM | `check_ram` (available %) via `check_nrpe!check_ram` | Client NRPE |

EPEL 9 has no `check_mem`. `check_ram` is a small script that warns when **available** memory is ≤ 20% (critical ≤ 10%). Load thresholds are `1.0` / `2.0` because these VMs have one CPU and ~600–800 MB RAM.

**UI:** **Hosts** = UP/DOWN (ping). **Services** = Ping Check, CPU Load, RAM.

**OS split:** CentOS uses `nrpe` and `/usr/lib64/nagios/plugins/`. Ubuntu `web01` uses `nagios-nrpe-server` and `/usr/lib/nagios/plugins/`.

**IP mapping:** `web01=.11`, `app01=.12`, `rmq01=.13`, `mc01=.14`, `db01=.15`, `nagios=.10` on `192.168.56.0/24`.

The default **localhost HTTP** check on the Nagios VM may show `403 Forbidden`. That is Apache denying `/`, not the vprofile app.
