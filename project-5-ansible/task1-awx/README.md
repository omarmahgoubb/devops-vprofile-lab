# Task 1 — Install AWX

One Ubuntu VM. 8 GB RAM. You install Docker, minikube, then AWX. You do not install MariaDB or Tomcat on this box.

## Boot the VM

From **Administrator** PowerShell (hostmanager writes the Windows hosts file):

```powershell
cd C:\Users\omara\Desktop\DEVOPS\Workshop_Senior_Steps\Lecture5_5-2-2025\project\task1-awx
vagrant plugin install vagrant-hostmanager
vagrant up awx01
vagrant ssh awx01
```

| Field | Value |
|---|---|
| Name | `awx01` |
| Box | `ubuntu/jammy64` |
| RAM | 8192 MB |
| CPUs | 2 |
| IP | `192.168.56.20` |
| SSH | `vagrant ssh awx01` (user `vagrant`) |

Then follow [commands/awx01_commands.md](commands/awx01_commands.md) **inside** the VM.

When AWX is up, from Windows open **http://127.0.0.1:8088** (Vagrant forwards guest `8080` → host `8088`) or **http://192.168.56.20:8080** if the port-forward on the VM is running.

User: `admin`. Password: from the kubectl secret command in that file.

Log: [progress.md](progress.md).
