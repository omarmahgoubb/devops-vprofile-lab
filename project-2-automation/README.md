# Project 2 — Automating the stack with Vagrant + Bash

Same five VMs as Project 1. Vagrant runs a shell script on each box after boot. You do not SSH in to type install commands.

## Hosts and scripts

| VM | IP | Script |
|---|---|---|
| `db01` | 192.168.56.15 | [scripts/db_provision.sh](scripts/db_provision.sh) |
| `mc01` | 192.168.56.14 | [scripts/mc_provision.sh](scripts/mc_provision.sh) |
| `rmq01` | 192.168.56.13 | [scripts/rmq_provision.sh](scripts/rmq_provision.sh) |
| `app01` | 192.168.56.12 | [scripts/app_provision.sh](scripts/app_provision.sh) |
| `web01` | 192.168.56.11 | [scripts/web_provision.sh](scripts/web_provision.sh) |

`db01`–`app01` are CentOS Stream 9. `web01` is Ubuntu 22.04 (APT + `sites-available`).

## Quickstart

Halt Project 1 first (same IPs):

```bash
# from project-1-manual
vagrant halt
```

Then:

```bash
vagrant plugin install vagrant-hostmanager
cd project-2-automation
vagrant up
```

That boots all five VMs and runs the provisioners. `app01` takes the longest (Maven). When it finishes, open **http://192.168.56.11**.

If `web01` times out on first SSH:

```bash
vagrant reload web01 --provision
```

`--provision` re-runs `web_provision.sh` after SSH works.

Re-run one script after you edit it:

```bash
vagrant provision app01
```

## What the scripts learned from the manual lab

- `dnf update` / `apt update` are commented out so provision is faster.
- Tomcat uses `/usr/lib/jvm/jre-11-openjdk` (avoids Java 17 404).
- Maven uses `mvn install -DskipTests` (JaCoCo failed on newer class files).
- Nginx writes `192.168.56.12 app01` into `/etc/hosts` if hostmanager has not run yet.
- `useradd tomcat` only if the user does not already exist.

Secrets in the scripts are examples (`admin123`, RabbitMQ `test`/`test`). Change them before any shared use.
