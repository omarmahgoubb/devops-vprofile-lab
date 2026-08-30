# Task 1 — Manual deployment on Azure

Create four VMs in the Azure portal. SSH into each one. Run the same install commands as Lecture 2 Task 1. There is no `web01`.

## Order

1. [create-vms.md](create-vms.md) — portal clicks, image, size, NSG. Live log: [progress.md](progress.md).
2. SSH into each VM and run:

| VM | Commands |
|---|---|
| `db01` | [commands/db01_commands.md](commands/db01_commands.md) |
| `mc01` | [commands/mc01_commands.md](commands/mc01_commands.md) |
| `rmq01` | [commands/rmq01_commands.md](commands/rmq01_commands.md) |
| `app01` | [commands/app01_commands.md](commands/app01_commands.md) |

3. In the `app01` NSG add inbound **8080**. Open [http://20.85.229.239:8080](http://20.85.229.239:8080) (`admin_vp` / `admin_vp`).

`db01` was created in the portal. `mc01` / `rmq01` / `app01` used [deploy/vm.json](deploy/vm.json) (same VNet, password SSH + swap on first boot). `app01` size is `Standard_B2s`.

## Login (replaces `vagrant ssh`)

We use **username + password**, not the `.pem` key.

Username: `azureuser`  
Password: set on each VM with portal **Reset password** (do not commit the password).

```bash
ssh azureuser@<that-vm-public-ip>
```

| VM | SSH |
|---|---|
| `db01` | `ssh azureuser@172.190.151.113` |
| `mc01` | `ssh azureuser@13.92.29.156` |
| `rmq01` | `ssh azureuser@20.85.239.154` |
| `app01` | `ssh azureuser@20.85.229.239` |

## What is the same as Lecture 2

`dnf`, EPEL, MariaDB, Memcached, RabbitMQ, Tomcat, Java 11, Maven, the WAR copy. That is why the image must be **CentOS Stream 9**.
