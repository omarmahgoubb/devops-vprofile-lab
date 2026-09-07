# DevOps VProfile Lab — Ansible / AWX (Lecture 5)

One **controller** VM talks to the app VMs over SSH. AWX is the browser UI. Ansible Core is the engine.

Controller: **Vagrant Ubuntu 22.04, 8 GB RAM** — host `awx01`, IP `192.168.56.20`.

## Tasks

| Task | What we do |
|---|---|
| **[task1-awx/](task1-awx/)** | **Done.** AWX at http://127.0.0.1:8088 (`admin`). |
| **[task2-ansible-core/](task2-ansible-core/)** | **Done.** Ansible Core on `awx01`. All five on-prem hosts `pong`. [progress.md](task2-ansible-core/progress.md). |
| **[task3-playbooks/](task3-playbooks/)** | **Done.** Playbooks from Lecture 2 scripts. Site: http://192.168.56.11. [progress.md](task3-playbooks/progress.md). |

All three tasks work for on-prem. Use `-i ~/ansible/hosts.ini` when running playbooks from `/vagrant`.

## Why this VM can manage on-prem

`awx01` is on the same `192.168.56.0/24` as Vagrant `db01`–`web01`. Later it can SSH to those IPs. It cannot SSH to Azure **private** IPs; Azure would be public IPs if we add that later.
