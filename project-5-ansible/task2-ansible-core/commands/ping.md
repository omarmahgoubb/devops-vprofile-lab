# Add the VMs and ping

`/vagrant` is only the `task1-awx` folder. The inventory is also copied there as `/vagrant/files/hosts.ini`.

```bash
mkdir -p ~/ansible
cp /vagrant/files/hosts.ini ~/ansible/hosts.ini
```

On **Windows**, start the five on-prem VMs if they are not running (other folder, other Vagrantfile):

```powershell
cd C:\Users\omara\Desktop\DEVOPS\Workshop_Senior_Steps\Lecture2_Vagrant_8-1-2025\Project\Task1
vagrant up
```

Your PC must have RAM for `awx01` (8 GB) **plus** those five small boxes. If it is tight, `vagrant up db01` only and ping that one first.

Back on `awx01`:

```bash
ansible -i ~/ansible/hosts.ini onprem -m ping
```

Each host should print `pong`. Example:

```text
db01 | SUCCESS => { "ping": "pong" }
```

If a host is `UNREACHABLE`, that VM is off, or SSH from `awx01` to `192.168.56.x` failed. Fix that before Task 3.

List what Ansible sees:

```bash
ansible-inventory -i ~/ansible/hosts.ini --list
```
