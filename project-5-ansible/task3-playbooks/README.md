# Task 3 — Shell scripts → playbooks

Same installs as Lecture 2 `*_provision.sh`, written as Ansible YAML. Run from `awx01` (Ansible Core). AWX job templates can wait.

| Script | Playbook | Host |
|---|---|---|
| `db_provision.sh` | [playbooks/db.yml](playbooks/db.yml) | `db01` |
| `mc_provision.sh` | [playbooks/mc.yml](playbooks/mc.yml) | `mc01` |
| `rmq_provision.sh` | [playbooks/rmq.yml](playbooks/rmq.yml) | `rmq01` |
| `app_provision.sh` | [playbooks/app.yml](playbooks/app.yml) | `app01` |
| `web_provision.sh` | [playbooks/web.yml](playbooks/web.yml) | `web01` |

All five: [playbooks/site.yml](playbooks/site.yml).

## On awx01

The playbooks are synced into the AWX VM as `/vagrant/files/playbooks/` (copy of this folder).

`/vagrant` is world-writable, so Ansible ignores `ansible.cfg` there. Always pass `-i ~/ansible/hosts.ini`.

```bash
cd /vagrant/files/playbooks
ansible-playbook -i ~/ansible/hosts.ini db.yml
ansible-playbook -i ~/ansible/hosts.ini mc.yml
ansible-playbook -i ~/ansible/hosts.ini rmq.yml
ansible-playbook -i ~/ansible/hosts.ini app.yml
ansible-playbook -i ~/ansible/hosts.ini web.yml
```

Or everything:

```bash
cd /vagrant/files/playbooks
ansible-playbook -i ~/ansible/hosts.ini site.yml
```

`app.yml` is the long one (Maven). When it finishes, on-prem site: **http://192.168.56.11** (`admin_vp` / `admin_vp`).
