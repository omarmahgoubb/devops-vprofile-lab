# Project 3 — Monitoring with Nagios (manual + automation)

Same five-tier app as Projects 1 and 2, plus a **Nagios Core** VM. Each app VM runs an **NRPE** agent so Nagios can check **ping**, **CPU load**, and **RAM**.

Do **not** run this at the same time as Project 1 or 2. They share `192.168.56.11`–`.15`.

## Hosts

| Host | Role | IP | OS |
|---|---|---|---|
| `db01` | MariaDB + NRPE | 192.168.56.15 | CentOS Stream 9 |
| `mc01` | Memcached + NRPE | 192.168.56.14 | CentOS Stream 9 |
| `rmq01` | RabbitMQ + NRPE | 192.168.56.13 | CentOS Stream 9 |
| `app01` | Tomcat + NRPE | 192.168.56.12 | CentOS Stream 9 |
| `web01` | Nginx + NRPE | 192.168.56.11 | Ubuntu 22.04 |
| `nagios` | Nagios Core + Apache | 192.168.56.10 | CentOS Stream 9 |

Bring-up order: **db01 → mc01 → rmq01 → app01 → web01 → nagios**.

| Check | Where it runs | UI |
|---|---|---|
| Ping | Nagios server → each IP | **Hosts** and **Services** |
| CPU Load (`check_load`) | NRPE on each VM | **Services** only |
| RAM (`check_ram`) | NRPE on each VM | **Services** only |

The **Hosts** page is ping only. Open **Current Status → Services** for CPU and RAM.

## Manual first, then automate

| Folder | What you do |
|---|---|
| [manual/](manual/) | Empty VMs. SSH in and follow `commands/`. |
| [automation/](automation/) | `vagrant up` runs the shell scripts. |

## Quickstart — manual

Halt Project 1 / 2 first, then:

```bash
cd project-3-monitoring-nagios/manual
vagrant up db01
vagrant ssh db01
```

Follow `commands/` in order: `db01` → `mc01` → `rmq01` → `app01` → `web01` → `nagios`. Use **Administrator** PowerShell so hostmanager can update the Windows hosts file.

Nagios UI: **http://192.168.56.10/nagios**  
App: **http://192.168.56.11**

## Quickstart — automation

Halt the manual (or Project 1 / 2) VMs first:

```bash
cd project-3-monitoring-nagios/automation
vagrant up
```

Login: `nagiosadmin` / `admin123` (lab only).

If `web01` times out on first SSH:

```bash
vagrant reload web01 --provision
```

## Notes from the lab

- `nagios-plugins-all` is often skipped on CentOS Stream 9. Install `nagios-plugins-load` (and friends) instead. There is no EPEL `check_mem`; RAM uses a small `check_ram` script (available memory).
- The Nagios server needs **`nagios-plugins-nrpe`** (`/usr/lib64/nagios/plugins/check_nrpe`). The `nrpe` package on clients is the agent; that plugin on the server is what runs the checks.
- Ubuntu `web01` uses `nagios-nrpe-server` (not `nrpe`) and plugins under `/usr/lib/nagios/plugins/`.
- Point Tomcat at Java 11 (`/usr/lib/jvm/jre-11-openjdk`). `/usr/lib/jvm/jre` often follows Java 17 after Maven.
- `dnf update` / `apt update` are commented in the scripts to save time.
