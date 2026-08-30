# Task 2 progress log

**Status: Task 2 complete.** One ARM template created the VNet and all four VMs. Custom data installed each role. App opened in the browser. No hand-run `dnf` on the VMs.

Resource group `vprofile` is **still up** (this run). Delete it when you want to stop paying. Recreate with [deploy/vprofile.json](deploy/vprofile.json).

## Inventory (East US, RG `vprofile`, VNet `vnet-eastus-1`)

Private IPs are DHCP this time (not the same as Task 1). Azure DNS still resolves `db01` / `mc01` / `rmq01` / `app01`, so the Java app does not need IP changes.

| VM | Role | Size | Public IP | Private IP | SSH |
|---|---|---|---|---|---|
| `db01` | MariaDB 3306 | `Standard_B1s` | `20.85.215.10` | `172.16.0.5` | `ssh azureuser@20.85.215.10` |
| `mc01` | Memcached 11211 | `Standard_B1s` | `20.102.55.91` | `172.16.0.7` | `ssh azureuser@20.102.55.91` |
| `rmq01` | RabbitMQ 5672 | `Standard_B1s` | `20.115.2.194` | `172.16.0.4` | `ssh azureuser@20.115.2.194` |
| `app01` | Tomcat 8080 | `Standard_B2s` | `168.62.61.151` | `172.16.0.6` | `ssh azureuser@168.62.61.151` |

Image: **CentOS Stream 9 Gen2** (ProComputers). SSH user: `azureuser` (password not stored). App login: `admin_vp` / `admin_vp`. DB: `admin` / `admin123`. RabbitMQ: `test` / `test`.

Public inbound: SSH 22 on all; **8080 already on `app01-nsg`** (in the template). DB / cache / RMQ stay private on the VNet.

App: http://168.62.61.151:8080

## SSH (copy/paste)

```bash
ssh azureuser@20.85.215.10
ssh azureuser@20.102.55.91
ssh azureuser@20.115.2.194
ssh azureuser@168.62.61.151
```

Custom data log on every VM:

```bash
sudo tail -f /var/log/vprofile-customdata.log
```

Done when the log ends with `db01 custom data done` / `mc01 custom data done` / `rmq01 custom data done` / `app01 custom data done`.

## What we did

1. Built [deploy/vprofile.json](deploy/vprofile.json) from [deploy/vprofile.bicep](deploy/vprofile.bicep) + [scripts/](scripts/) (`db01.sh`, `mc01.sh`, `rmq01.sh`, `app01.sh`).
2. Created empty RG `vprofile` in East US (Task 1 RG had been deleted).
3. Portal → **Deploy a custom template** → load `vprofile.json` → only `adminPassword` → Review + create.
4. Azure marked the deployment **Succeeded** when the four VMs existed. Custom data kept running (Maven on `app01` is the long one).
5. SSH as `azureuser` to the public IPs above. App worked at http://168.62.61.151:8080 (`admin_vp` / `admin_vp`).

## What Custom data does (same as Task 1, unattended)

Every script: enable password SSH, 2G swap, skip full `dnf update` (B1s OOM).

| VM | Script | Installs |
|---|---|---|
| `db01` | [scripts/db01.sh](scripts/db01.sh) | EPEL, git, MariaDB, `accounts` + `admin`/`admin123`, SQL dump, firewall 3306 |
| `mc01` | [scripts/mc01.sh](scripts/mc01.sh) | Memcached on `0.0.0.0`, firewall 11211/tcp + 11111/udp |
| `rmq01` | [scripts/rmq01.sh](scripts/rmq01.sh) | `centos-release-rabbitmq-38`, user `test`/`test`, firewall 5672 |
| `app01` | [scripts/app01.sh](scripts/app01.sh) | Java 11, Tomcat 9.0.75, Maven `-DskipTests`, `ROOT.war`, firewall 8080 |

`app01-nsg` rule `allow-8080` is in the template (Task 1 added this by hand after Tomcat was up).

## Notes for next time

- Deployment Succeeded ≠ Custom data finished. Wait, then check the log.
- `app01` needs ~15–25 minutes for Maven.
- Private IPs change on recreate. Use hostnames, not the numbers above.
- Delete RG `vprofile` when done. Recreate with the same JSON.
