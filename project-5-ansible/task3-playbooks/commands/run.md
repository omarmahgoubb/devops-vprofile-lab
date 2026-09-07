# Run the playbooks (on awx01)

`/vagrant` is world-writable, so Ansible **ignores** `ansible.cfg` there. Always pass `-i`:

```bash
cd /vagrant/files/playbooks
ansible-playbook -i ~/ansible/hosts.ini db.yml
ansible-playbook -i ~/ansible/hosts.ini mc.yml
ansible-playbook -i ~/ansible/hosts.ini rmq.yml
ansible-playbook -i ~/ansible/hosts.ini app.yml
ansible-playbook -i ~/ansible/hosts.ini web.yml
```

One shot:

```bash
cd /vagrant/files/playbooks
ansible-playbook -i ~/ansible/hosts.ini site.yml
```

Done when http://192.168.56.11 opens (`admin_vp` / `admin_vp`).
