# Personal notes — Lecture 4 (checked)

On-prem (projects 1–3): 5-VM stack by hand, then Vagrant + bash, then Nagios.

Cloud: session was AWS; we did **Azure**.

- 4 VMs, no Nginx. Browse `app01:8080`.
- Small sizes. Same VNet. SSH + password.
- Task 1 manual → Task 2 Custom data scripts → Task 3 Azure services.

Image: **CentOS Stream 9 Gen2 (ProComputers)** so Lecture 2 `dnf` / `centos-release-rabbitmq-38` stay the same.

## Task 1 — done

Resource group `vprofile`, East US, VNet `vnet-eastus-1`.

| VM | Public IP | Private IP |
|---|---|---|
| db01 | 172.190.151.113 | 172.16.0.4 |
| mc01 | 13.92.29.156 | 172.16.0.5 |
| rmq01 | 20.85.239.154 | 172.16.0.6 |
| app01 | 20.85.229.239 | 172.16.0.7 |

App worked at http://20.85.229.239:8080 (`admin_vp` / `admin_vp`). Then we **deleted RG `vprofile`** to stop cost. Recreate from `task1-manual/deploy/vm.json` when needed.

Gotchas: image blocks password SSH; B1s needs swap or `dnf` is Killed; do not create a second VNet; `app01` is B2s; NSG 8080 on app only.

Reusable template: `task1-manual/deploy/vm.json`. Full log: `task1-manual/progress.md`.
