# Project 3 — Automation: stack + Nagios + NRPE

Same six VMs as the [manual](../manual/) lab. Vagrant runs the shell scripts after boot.

## Hosts and scripts

| VM | IP | Script |
|---|---|---|
| `db01` | 192.168.56.15 | [scripts/db_provision.sh](scripts/db_provision.sh) then [nrpe_centos.sh](scripts/nrpe_centos.sh) |
| `mc01` | 192.168.56.14 | [scripts/mc_provision.sh](scripts/mc_provision.sh) then [nrpe_centos.sh](scripts/nrpe_centos.sh) |
| `rmq01` | 192.168.56.13 | [scripts/rmq_provision.sh](scripts/rmq_provision.sh) then [nrpe_centos.sh](scripts/nrpe_centos.sh) |
| `app01` | 192.168.56.12 | [scripts/app_provision.sh](scripts/app_provision.sh) then [nrpe_centos.sh](scripts/nrpe_centos.sh) |
| `web01` | 192.168.56.11 | [scripts/web_provision.sh](scripts/web_provision.sh) (Nginx + NRPE) |
| `nagios` | 192.168.56.10 | [scripts/nagios_provision.sh](scripts/nagios_provision.sh) |

`dnf update` and `apt update` are commented out (slow). Tomcat uses Java 11. Web UI user: `nagiosadmin` / `admin123`.

## Quickstart

Halt Project 1, Project 2, or the Project 3 manual VMs first:

```bash
vagrant plugin install vagrant-hostmanager
cd project-3-monitoring-nagios/automation
vagrant up
```

When it finishes:

- App: **http://192.168.56.11**
- Nagios: **http://192.168.56.10/nagios** — **Services** for CPU Load and RAM

If `web01` times out on first SSH:

```bash
vagrant reload web01 --provision
```

Re-run one script after you edit it:

```bash
vagrant provision nagios
```
