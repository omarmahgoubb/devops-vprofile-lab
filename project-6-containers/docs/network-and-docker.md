# Network and Docker on the ubuntu VM

## Two NICs (required)

| Adapter | VirtualBox mode | Why |
|---|---|---|
| NIC1 | **Host-Only** | Windows can `ssh mahgoub@192.168.56.x` |
| NIC2 | **NAT** | Guest can reach the internet / Docker Hub |

Host-Only alone has **no** public DNS. Then:

```text
lookup registry-1.docker.io on 127.0.0.53:53: server misbehaving
```

After NIC2 is NAT, in the VM:

```bash
ip -4 addr
ping -c 2 8.8.8.8
ping -c 2 registry-1.docker.io
```

You want: `192.168.56.x` (SSH) **and** `10.0.2.x` (NAT). Then:

```bash
docker pull tomcat:8-jre11
```

## SSH from Windows

On the VM:

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
ip -4 addr
```

On Windows:

```powershell
ssh mahgoub@192.168.56.xxx
```

## Docker

```bash
docker --version
docker ps
```

If Docker is missing:

```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
```

Log out and back in, then `docker ps` again.
