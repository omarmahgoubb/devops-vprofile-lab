# DevOps VProfile Lab — Manual → Automation → Monitoring → Azure

This monorepo documents my journey from **manual provisioning** to **automated builds**, **monitoring**, and **Azure** for a multi-tier Java web application.

## What’s inside

- **[project-1-manual/](project-1-manual/)** — SSH into each VM and run the commands by hand (five app VMs).
- **[project-2-automation/](project-2-automation/)** — the same stack, provisioned by Vagrant shell scripts.
- **[project-3-monitoring-nagios/](project-3-monitoring-nagios/)** — same stack plus Nagios Core and NRPE (CPU / RAM / ping). Manual and automated.
- **[project-4-azure/](project-4-azure/)** — same app on Azure (no Nginx). Task 1 manual. Task 2 one-file Custom data deploy. Task 3 next.
- **[docs/](docs/)** — architecture, ports, and monitoring notes.

## Stack and bring-up order

| Host | Role | IP | OS |
|---|---|---|---|
| `db01` | MariaDB (3306) | 192.168.56.15 | CentOS Stream 9 |
| `mc01` | Memcached (11211/tcp, 11111/udp) | 192.168.56.14 | CentOS Stream 9 |
| `rmq01` | RabbitMQ (5672) | 192.168.56.13 | CentOS Stream 9 |
| `app01` | Tomcat + vprofile WAR (8080) | 192.168.56.12 | CentOS Stream 9 |
| `web01` | Nginx reverse proxy (80 → `app01:8080`) | 192.168.56.11 | Ubuntu 22.04 |
| `nagios` | Nagios Core (Project 3) | 192.168.56.10 | CentOS Stream 9 |

Bring-up order: **MariaDB → Memcached → RabbitMQ → Tomcat → Nginx** (then **Nagios** in Project 3).

Client → `http://192.168.56.11` (Nginx) → `app01:8080` (Tomcat) → `db01` / `mc01` / `rmq01`.

## Prerequisites

- VirtualBox and Vagrant
- `vagrant plugin install vagrant-hostmanager`

Do **not** run Project 1, Project 2, and Project 3 at the same time. They share `192.168.56.11`–`.15`.

Use **Administrator** PowerShell on Windows so hostmanager can update the hosts file.

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

## Quickstart — Project 3 (Nagios)

Halt Project 1 / 2 first.

**Manual** (SSH + command files, including NRPE and Nagios):

```bash
cd project-3-monitoring-nagios/manual
vagrant up db01
```

Follow `commands/` (`db01` → … → `web01` → `nagios`).

**Automated** (six VMs + NRPE + Nagios):

```bash
cd project-3-monitoring-nagios/automation
vagrant up
```

- App: **http://192.168.56.11**
- Nagios: **http://192.168.56.10/nagios** (`nagiosadmin` / `admin123`)
- CPU and RAM: **Current Status → Services** (the Hosts page is ping only)

## Quickstart — Project 4 (Azure)

Four VMs in one VNet, no Nginx. Browse Tomcat on `app01:8080`. See [project-4-azure/](project-4-azure/).

- Task 1 (manual): [project-4-azure/task1-manual/deploy/vm.json](project-4-azure/task1-manual/deploy/vm.json)
- Task 2 (Custom data, one file): [project-4-azure/task2-automated/deploy/vprofile.json](project-4-azure/task2-automated/deploy/vprofile.json)

Delete the resource group when the lab is done so you stop paying.

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
├─ project-3-monitoring-nagios/
│  ├─ README.md
│  ├─ manual/
│  └─ automation/
└─ project-4-azure/
   ├─ README.md
   ├─ docs/
   ├─ task1-manual/
   │  ├─ commands/
   │  ├─ deploy/          # vm.json — one VM
   │  └─ progress.md
   └─ task2-automated/
      ├─ deploy/          # vprofile.json — all 4 VMs + Custom data
      ├─ scripts/
      └─ progress.md
```

## Why manual first?

Doing it by hand once makes the **automation spec obvious**. Each command becomes a line in a script — then monitoring proves the stack stays healthy.

> Sample lab passwords (`admin123`, RabbitMQ `test`/`test`) are for local learning only. Do not reuse them.
