# Task 3 progress log

**Status: Task 3 complete.** Playbooks ran from `awx01` against the Lecture 2 Task 1 VMs. Site opened at http://192.168.56.11 (`admin_vp` / `admin_vp`).

Always pass inventory (`/vagrant` is world-writable, so Ansible ignores `ansible.cfg` there):

```bash
cd /vagrant/files/playbooks
ansible-playbook -i ~/ansible/hosts.ini db.yml
ansible-playbook -i ~/ansible/hosts.ini mc.yml
ansible-playbook -i ~/ansible/hosts.ini rmq.yml
ansible-playbook -i ~/ansible/hosts.ini app.yml
ansible-playbook -i ~/ansible/hosts.ini web.yml
```

These VMs were reused from an earlier lab. Playbooks had to tolerate that:

- `db.yml`: root already had password `admin123` (skip fresh `ALTER USER`).
- `rmq.yml`: user `test` already existed (`already exists` is OK).
- `app.yml`: Tomcat already unpacked (skip extract).

Recap: every play `failed=0`.
