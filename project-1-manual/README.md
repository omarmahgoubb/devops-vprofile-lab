# Project 1 — Manual build (SSH)

Exact commands used to build the multi-tier Java app by hand. Each host is a Vagrant VM. You SSH in and run the file for that host.

## Hosts

| VM | IP | Commands |
|---|---|---|
| `db01` | 192.168.56.15 | [commands/db01_mysql.md](commands/db01_mysql.md) |
| `mc01` | 192.168.56.14 | [commands/mc01_memcache.md](commands/mc01_memcache.md) |
| `rmq01` | 192.168.56.13 | [commands/rmq01_rabbitmq.md](commands/rmq01_rabbitmq.md) |
| `app01` | 192.168.56.12 | [commands/app01_tomcat.md](commands/app01_tomcat.md) |
| `web01` | 192.168.56.11 | [commands/web01_nginx.md](commands/web01_nginx.md) |

## Start

```bash
vagrant plugin install vagrant-hostmanager
cd project-1-manual
vagrant up db01
vagrant ssh db01
```

Bring VMs up one at a time in that table order. After `web01`, open **http://192.168.56.11**.

`web01` uses Ubuntu (`ubuntu/jammy64`). First boot may miss SSH; if Vagrant times out, open the VM in VirtualBox to confirm the login prompt, then:

```bash
vagrant reload web01
```
