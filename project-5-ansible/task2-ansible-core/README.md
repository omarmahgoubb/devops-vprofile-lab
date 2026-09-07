# Task 2 — Ansible Core + add the VMs

Same VM as Task 1 (`awx01`). You install the **engine** (`ansible`), write an **inventory** (the address book), then `ping` the app VMs.

AWX is only the website. It does not replace this step.

Do **on-prem first** (`192.168.56.11`–`.15`). Those VMs must be **running** (Lecture 2 Task 1 / project-1 Vagrantfile). Azure can wait.

## Order

1. [commands/install_ansible.md](commands/install_ansible.md) — `ansible-core` on `awx01`
2. Copy [inventory/hosts.ini](inventory/hosts.ini) onto `awx01` (or use `/vagrant/../task2-ansible-core/inventory/hosts.ini`)
3. [commands/ping.md](commands/ping.md) — `ansible onprem -m ping`

**Done when** every on-prem host replies `pong`. Do not write playbooks yet (Task 3).
