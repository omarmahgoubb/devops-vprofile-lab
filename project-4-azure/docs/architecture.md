# Architecture — Azure Task 1 and Task 2

Four Linux VMs in resource group **`vprofile`** (East US), one VNet **`vnet-eastus-1`** / **`snet-eastus-1`** (`172.16.0.0/24`). No Nginx.

Azure DNS in the VNet resolves the short names `db01` / `mc01` / `rmq01` / `app01`, so the Java app keeps the same hostnames as Vagrant hostmanager. Private IPs are DHCP and change between recreates.

## Task 2 — current run (Custom data)

| Host | Private IP | Public IP | Role |
|---|---|---|---|
| `db01` | `172.16.0.5` | `20.85.215.10` | MariaDB TCP 3306 |
| `mc01` | `172.16.0.7` | `20.102.55.91` | Memcached TCP 11211, UDP 11111 |
| `rmq01` | `172.16.0.4` | `20.115.2.194` | RabbitMQ TCP 5672 |
| `app01` | `172.16.0.6` | `168.62.61.151` | Tomcat TCP 8080 |

**Flow:** Client → [http://168.62.61.151:8080](http://168.62.61.151:8080) → Tomcat → cache (`mc01:11211`) and DB (`db01:3306`); async work via `rmq01:5672`.

SSH: `ssh azureuser@<public-ip>`. Log: [task2-automated/progress.md](../task2-automated/progress.md).

## Task 1 — historical (manual, then RG deleted)

| Host | Private IP | Public IP | Role |
|---|---|---|---|
| `db01` | `172.16.0.4` | `172.190.151.113` | MariaDB TCP 3306 |
| `mc01` | `172.16.0.5` | `13.92.29.156` | Memcached TCP 11211, UDP 11111 |
| `rmq01` | `172.16.0.6` | `20.85.239.154` | RabbitMQ TCP 5672 |
| `app01` | `172.16.0.7` | `20.85.229.239` | Tomcat TCP 8080 |

App was http://20.85.229.239:8080. Log: [task1-manual/progress.md](../task1-manual/progress.md).

## NSG

- All VMs: inbound SSH 22 (lab).
- **`app01-nsg`:** inbound `allow-8080`, TCP **8080**, priority 1010, source Any. Task 1 added this after Tomcat was up. Task 2 puts it in [task2-automated/deploy/vprofile.json](../task2-automated/deploy/vprofile.json).
- 3306 / 11211 / 5672 are not opened to the internet. VNet-to-VNet is already allowed.

## Bring-up

Task 1: MariaDB → Memcached → RabbitMQ → Tomcat (by hand).

Task 2: all four VMs start together; Custom data installs each role. The app uses hostnames, so it is fine if Tomcat is ready a few minutes after MariaDB.
