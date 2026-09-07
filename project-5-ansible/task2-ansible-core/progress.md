# Task 2 progress log

**Status: Task 2 complete** (on-prem). Ansible Core 2.12 on `awx01`. All five Vagrant hosts replied `pong`.

| Host | Result | Note |
|---|---|---|
| `db01` `mc01` `rmq01` `app01` | `pong` | Password SSH (`vagrant` / `vagrant`) |
| `web01` | `pong` after fix | Ubuntu `jammy64` was public-key only. Enabled `PasswordAuthentication` on the Lecture 2 Task 1 `web01`. |

Inventory: `~/ansible/hosts.ini` on `awx01` (copy of [inventory/hosts.ini](inventory/hosts.ini)). `/vagrant` is only `task1-awx`, so use `/vagrant/files/hosts.ini`.
