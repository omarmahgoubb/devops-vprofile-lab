# Install Ansible Core on awx01

Second SSH into the controller (leave AWX port-forward in the other window):

```powershell
cd C:\Users\omara\Desktop\DEVOPS\Workshop_Senior_Steps\Lecture5_5-2-2025\project\task1-awx
vagrant ssh awx01
```

Install the engine and `sshpass` (needed because the lab uses the Vagrant password `vagrant`, not a key yet):

```bash
sudo apt update
sudo apt install -y ansible-core sshpass
ansible --version
```

You should see `ansible` and a version number. That is enough for Task 2.
