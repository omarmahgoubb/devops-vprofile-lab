# Project 3 — Manual: stack + Nagios + NRPE

Vagrant only creates empty VMs. You SSH in and follow the command file for that host.

Same five app VMs as Project 1, then NRPE on each, then the Nagios server.

## Hosts

| VM | IP | Commands |
|---|---|---|
| `db01` | 192.168.56.15 | [commands/db01_commands.md](commands/db01_commands.md) |
| `mc01` | 192.168.56.14 | [commands/mc01_commands.md](commands/mc01_commands.md) |
| `rmq01` | 192.168.56.13 | [commands/rmq01_commands.md](commands/rmq01_commands.md) |
| `app01` | 192.168.56.12 | [commands/app01_commands.md](commands/app01_commands.md) |
| `web01` | 192.168.56.11 | [commands/web01_commands.md](commands/web01_commands.md) |
| `nagios` | 192.168.56.10 | [commands/nagios_commands.md](commands/nagios_commands.md) |

Each of `db01`–`web01` has **section 1** (the app, like Project 1) and **section 2–3** (NRPE, then CPU/RAM). Install Nagios last so the agents already exist.

## Start

Halt Project 1, Project 2, or the Project 3 automation VMs first (same IPs).

```bash
vagrant plugin install vagrant-hostmanager
cd project-3-monitoring-nagios/manual
vagrant up db01
vagrant ssh db01
```

Bring VMs up one at a time in table order. After `web01`, open **http://192.168.56.11**. After `nagios`, open **http://192.168.56.10/nagios**.

CPU and RAM appear under **Current Status → Services**, not **Hosts**.

`web01` uses Ubuntu. First boot may miss SSH:

```bash
vagrant reload web01
```
