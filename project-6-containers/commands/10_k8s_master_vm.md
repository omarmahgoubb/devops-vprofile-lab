# kubeadm — create `k8s-master` (VirtualBox)

Leave the 12 GB Docker VM `ubuntu` **Powered Off** (CPU). Do not clone it.

ISO we used: `C:\Users\omara\Downloads\ubuntu-24.04.4-live-server-amd64.iso`  
(VirtualBox remembered that path; the file was in Recycle Bin and we restored it.)

## Wizard

| Setting | Value |
|---|---|
| Name | `k8s-master` |
| ISO | Ubuntu **Server** 24.04.4 LTS (AMD64) |
| Unattended | OK. User `mahgoub`, hostname `k8s-master` |
| Domain | `local` (not `myguest.virtualbox.org`) |
| Guest Additions | off |
| RAM | **4096 MB** |
| CPUs | **2** (kubeadm refuses 1) |
| EFI | off |
| Disk | new VDI, 20–25 GB (not `ubuntu.vdi`) |

## Network (Settings, before first start)

| Adapter | Attached to | Why |
|---|---|---|
| 1 | **Host-only Adapter** (`VirtualBox Host-Only Ethernet Adapter`) | SSH from Windows |
| 2 | **NAT** | `apt` / image pulls |

## After login (in the VM or MobaXterm)

SSH: host `192.168.56.124`, user `mahgoub`, port 22.

```bash
hostname
nproc
free -h
ip -4 addr
ping -c 2 8.8.8.8
```

What we got:

| Check | Value |
|---|---|
| hostname | `k8s-master` |
| CPUs | `2` |
| RAM | `3.8G` |
| `enp0s3` | `192.168.56.124` (Host-Only) |
| `enp0s8` | `10.0.3.15` (NAT) |

If SSH is refused: `sudo apt install -y openssh-server && sudo systemctl enable --now ssh`.
