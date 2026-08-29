# DevOps VProfile Lab — Manual → Automation → Monitoring

This monorepo documents my journey from **manual provisioning** to **automated builds** and **monitoring** for a multi-tier Java web application.

## What’s inside

- **[project-1-manual/](project-1-manual/)** — SSH into each VM and run the commands by hand.
- **[project-2-automation/](project-2-automation/)** — the same stack, provisioned by Vagrant shell scripts.
- **[project-3-monitoring-nagios/](project-3-monitoring-nagios/)** — Nagios Core (`mon01`) pinging the five app VMs.
- **[docs/](docs/)** — architecture, ports, and monitoring notes.

## Interactive walkthrough

- **Code2Tutorial (auto-generated guide)** — click-through tutorial with chapters and command blocks:  
  https://code2tutorial.com/tutorial/3cab15e6-750e-4e20-a74c-2ace648c7745/index.md

## Stack and bring-up order

| Host | Role | IP | OS |
|---|---|---|---|
| `db01` | MariaDB (3306) | 192.168.56.15 | CentOS Stream 9 |
| `mc01` | Memcached (11211/tcp, 11111/udp) | 192.168.56.14 | CentOS Stream 9 |
| `rmq01` | RabbitMQ (5672) | 192.168.56.13 | CentOS Stream 9 |
| `app01` | Tomcat + vprofile WAR (8080) | 192.168.56.12 | CentOS Stream 9 |
| `web01` | Nginx reverse proxy (80 → `app01:8080`) | 192.168.56.11 | Ubuntu 22.04 |
| `mon01` | Nagios (Project 3) | 192.168.56.16 | Rocky 9 |

Bring-up order: **MariaDB → Memcached → RabbitMQ → Tomcat → Nginx**.

Client → `http://192.168.56.11` (Nginx) → `app01:8080` (Tomcat) → `db01` / `mc01` / `rmq01`.

## Prerequisites

- VirtualBox and Vagrant
- `vagrant plugin install vagrant-hostmanager`

Do **not** run Project 1 and Project 2 at the same time. They share the same IPs.

## Quickstart — Project 1 (manual)

```bash
cd project-1-manual
vagrant up db01
vagrant ssh db01
```

Then follow `commands/` in this order: `db01` → `mc01` → `rmq01` → `app01` → `web01`.

## Quickstart — Project 2 (automation)

Halt Project 1 first (`vagrant halt` in that folder), then:

```bash
cd project-2-automation
vagrant up
```

Vagrant boots all five VMs and runs `scripts/*_provision.sh`. When it finishes, open **http://192.168.56.11**.

If `web01` times out waiting for SSH on first boot (common with `ubuntu/jammy64`):

```bash
vagrant reload web01 --provision
```

## Lessons from the lab (applied here)

- Create the `accounts` database **before** importing `db_backup.sql`.
- Point Tomcat at **Java 11** (`/usr/lib/jvm/jre-11-openjdk`). `/usr/lib/jvm/jre` often follows Java 17 after Maven installs, and the app then returns a Tomcat 404.
- Skip pinned `dnf remove java-17-...-<old-version>` — those RPM versions change.
- Nginx must resolve `app01` before `systemctl restart nginx`, or you get `host not found in upstream`.
- `web01` needs a longer `boot_timeout` (1000s). First SSH can fail; `vagrant reload web01` usually works.

## Folder layout

```
devops-vprofile-lab/
├─ README.md
├─ .gitignore
├─ docs/
│  ├─ architecture.md
│  └─ monitoring.md
├─ project-1-manual/
│  ├─ Vagrantfile
│  ├─ README.md
│  └─ commands/
├─ project-2-automation/
│  ├─ Vagrantfile
│  ├─ README.md
│  └─ scripts/
└─ project-3-monitoring-nagios/
   ├─ Vagrantfile
   ├─ README.md
   └─ scripts/
```

## Why manual first?

Doing it by hand once makes the **automation spec obvious**. Each command becomes a line in a script — then monitoring proves the stack stays healthy.

> Sample lab passwords (`admin123`, RabbitMQ `test`/`test`) are for local learning only. Do not reuse them.
