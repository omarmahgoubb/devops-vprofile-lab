# Step 0 — SSH, NAT, Docker

On Windows (Host-Only IP of the `ubuntu` VM):

```powershell
ssh mahgoub@192.168.56.123
```

Host-Only alone has no public DNS. Docker Hub then fails with `lookup registry-1.docker.io ... server misbehaving`. NIC2 must be **NAT**. If `enp0s8` is down or has no IP:

```bash
ip link
sudo ip link set enp0s8 up
```

Make NAT DHCP survive reboot (this VM only had `enp0s3` in cloud-init):

```bash
sudo tee /etc/netplan/99-enp0s8.yaml >/dev/null <<'EOF'
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: true
      dhcp4-overrides:
        route-metric: 50
EOF

sudo chmod 600 /etc/netplan/99-enp0s8.yaml
sudo netplan apply
ip -4 addr show enp0s8
ip route
ping -c 2 8.8.8.8
```

You want `10.0.3.15` (or `10.0.2.x`) on `enp0s8` and a default route. Then:

```bash
docker --version
docker pull tomcat:8-jre11
```

If Docker is missing:

```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
```

Log out and back in, then `docker ps` without `sudo`.
