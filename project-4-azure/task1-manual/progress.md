# Task 1 progress log

**Status: Task 1 complete** (lab then torn down). Resource group `vprofile` is deleted after a successful run so we do not keep paying. IPs below are historical. Recreate with [deploy/vm.json](deploy/vm.json) + the command files.

## Final inventory (East US, RG `vprofile`, VNet `vnet-eastus-1`)

| VM | Role | Size | Public IP | Private IP | SSH |
|---|---|---|---|---|---|
| `db01` | MariaDB 3306 | `Standard_B1s` | `172.190.151.113` | `172.16.0.4` | `ssh azureuser@172.190.151.113` |
| `mc01` | Memcached 11211 | `Standard_B1s` | `13.92.29.156` | `172.16.0.5` | `ssh azureuser@13.92.29.156` |
| `rmq01` | RabbitMQ 5672 | `Standard_B1s` | `20.85.239.154` | `172.16.0.6` | `ssh azureuser@20.85.239.154` |
| `app01` | Tomcat 8080 | `Standard_B2s` | `20.85.229.239` | `172.16.0.7` | `ssh azureuser@20.85.229.239` |

Image: **CentOS Stream 9 Gen2** (ProComputers). SSH user: `azureuser` (password not stored). App login: `admin_vp` / `admin_vp`. DB: `admin` / `admin123`. RabbitMQ: `test` / `test`.

Public inbound: SSH 22 on all; **8080 only on `app01-nsg`**. DB / cache / RMQ stay private on the VNet.

### NSG update so the website is reachable

The template / portal create only opens **SSH 22**. The browser cannot hit Tomcat until we add a second inbound rule on **`app01-nsg`** (not on db/mc/rmq).

| Field | Value |
|---|---|
| NSG | `app01-nsg` |
| Rule name | `allow-8080` |
| Priority | `1010` |
| Source | Any |
| Destination | Any |
| Service / port | TCP **8080** |
| Action | Allow |

Portal: `vprofile` → `app01-nsg` → **Inbound security rules** → **Add** → values above.

```powershell
az network nsg rule create --resource-group vprofile --nsg-name app01-nsg --name allow-8080 --priority 1010 --access Allow --protocol Tcp --direction Inbound --source-address-prefixes '*' --destination-port-ranges 8080
```

`firewalld` on `app01` must also allow 8080 (already in [commands/app01_commands.md](commands/app01_commands.md)). Both are required: Azure NSG **and** the VM firewall.

### What we learned (keep for Task 2)

- Image forces `PasswordAuthentication no` until custom data or Run Command flips it.
- `Standard_B1s` (1 GiB) OOMs `dnf` without 2G swap. Skip full `dnf update` on B1s after `db01`.
- All four VMs must share **`vnet-eastus-1`**. A new VNet (`vnet-eastus-2`) breaks the app.
- Azure CLI create/delete from this chat needs extra MFA. Portal **Deploy a custom template** + [deploy/vm.json](deploy/vm.json) is the path for `mc01` / `rmq01` / `app01`.

---

We write each step here after we do it, so the GitHub repo matches what actually happened.

## Step 1 — Resource group (done)

- **Name:** `vprofile`
- **Region:** `eastus` (East US)
- **Subscription:** Azure Sponsership
- **Contents:** empty (checked with `az resource list`)

This is a new group. We are not using `INCODEDRG_MAIN` or any other existing group.

## Step 2 — Create `db01` (now)

Portal → Virtual machines → Create. **Basics** tab only — exact values:

| Field | Value | Keep or change |
|---|---|---|
| Subscription | Azure Sponsorship | keep |
| Resource group | `vprofile` | keep |
| Virtual machine name | `db01` | keep |
| Region | (US) East US | keep |
| Availability options | Availability zone | keep |
| Zone options | Self-selected zone | keep |
| Availability zone | Zone 1 | keep |
| Security type | Standard (if CentOS Stream 9 is missing under Trusted launch, switch to Standard) | change if needed |
| Image | **See all images** → click **CentOS Stream 9 Gen2 (CentOS 9)** by **ProComputers** (the Gen2 tile, not Stream 10, not Ntegral) | **change** (now Ubuntu — wrong) |
| VM architecture | x64 | keep |
| Size | **See all sizes** → `Standard_B1s` (1 vCPU, 1 GiB) | **change** (now D2s_v3 — too expensive) |
| Run with Azure Spot discount | unchecked | keep |
| Authentication type | SSH public key | keep |
| Username | `azureuser` | keep |
| SSH public key source | Generate new key pair | keep |
| Key pair name | `vprofile-key` | set this so the other 3 VMs reuse it |
| Public inbound ports | Allow selected ports → **SSH (22)** | keep / set |

**Disks** tab:

| Field | Value | Keep or change |
|---|---|---|
| Encryption at host | unchecked | keep (subscription is not registered for it) |
| OS disk size | Image default (30 GiB) | keep |
| OS disk type | **Standard SSD** | **change** (Premium SSD is ~SAR 20/VM and unused extra speed) |
| Delete with VM | checked | keep (lab cleanup is easier) |
| Enable Ultra Disk compatibility | unchecked | keep |
| Key management | Platform-managed key | keep |
| Data disks | none — do not add any | keep |
| Ephemeral OS disk | None | keep |

**Networking** tab:

| Field | Value | Keep or change |
|---|---|---|
| Virtual network | `vnet-eastus-1` (in `vprofile`) | keep — reuse this same VNet on mc01 / rmq01 / app01 |
| Subnet | `snet-eastus-1` (`172.16.0.0/24`) | keep |
| Public IP | `db01-ip` (new) | keep (needed for SSH) |
| NIC network security group | Basic | keep |
| Public inbound ports | Allow selected ports | keep |
| Select inbound ports | SSH (22) only | keep — do not add 3306 |
| Delete public IP and NIC when VM is deleted | **checked** | **change** (easier lab cleanup) |
| Enable accelerated networking | unchecked | keep (B1s cannot use it) |
| Load balancing options | None | keep |

The yellow SSH warning is expected for this lab. The ~SAR 30 “outbound 100 GB” line is only an estimate — you pay that only if you actually transfer that much.

**Management / Monitoring / Advanced / Tags:** leave defaults, except Monitoring:

| Field | Value |
|---|---|
| Enable recommended alert rules | unchecked |
| Boot diagnostics | **Disabled** |
| Enable OS guest diagnostics | unchecked |
| Enable application health monitoring | unchecked |
| Custom data | empty (Task 2) |
| Tags | none, or optional `Project` = `vprofile` |

`db01` is **Running**.

| | |
|---|---|
| Public IP | `172.190.151.113` |
| Private IP | `172.16.0.4` |
| Image | `centos-stream-9-gen2` |

Login is **username + password** (not the `.pem` key): user `azureuser`.

The image ships with `PasswordAuthentication no` in `/etc/ssh/sshd_config.d/01-localconfig.conf`. We changed that to `yes` and restarted `sshd` via Azure Run Command. Set the password on the VM with portal **Reset password**, then:

```bash
ssh azureuser@172.190.151.113
```

After login: `cat /etc/os-release`, confirm CentOS Stream 9.

`sudo dnf update -y` **completed** on `db01` (kernel + 240 packages). Then `dnf install git mariadb-server` was **Killed** — OOM on `Standard_B1s` (1 GiB RAM). MariaDB never installed.

Fix: add 2G swap, then install. MariaDB commands after that are **done** (user completed [commands/db01_commands.md](commands/db01_commands.md)).

## Step 3 — Create `mc01` (now)

Same as `db01`, except the name. Reuse VNet `vnet-eastus-1`. Password login for `azureuser` again (Reset password + enable `PasswordAuthentication` if SSH says `publickey` only).

| Field | Value |
|---|---|
| Resource group | `vprofile` |
| Virtual machine name | `mc01` |
| Region | East US |
| Image | CentOS Stream 9 Gen2 (ProComputers) |
| Size | `Standard_B1s` |
| Username | `azureuser` |
| Inbound | SSH (22) only |
| VNet | **existing** `vnet-eastus-1` / `snet-eastus-1` |
| Disk | Standard SSD, delete with VM |
| Boot diagnostics | Disabled |

`mc01` recreated from `deploy/vm.json` on **`vnet-eastus-1`** (correct). Same size as `db01` (`Standard_B1s`).

| | `db01` | `mc01` |
|---|---|---|
| Public IP | `172.190.151.113` | `13.92.29.156` |
| Private IP | `172.16.0.4` | `172.16.0.5` |
| VNet | `vnet-eastus-1` | `vnet-eastus-1` |

Memcached commands on `mc01` are done.

## Step 4 — Create `rmq01` (now)

Same template as `mc01`: portal **Deploy a custom template** → load `deploy/vm.json`.

| Parameter | Value |
|---|---|
| Resource group | `vprofile` |
| vmName | `rmq01` |
| vmSize | `Standard_B1s` |
| vnetName | `vnet-eastus-1` |
| adminPassword | same `azureuser` password |

Then SSH and follow [commands/rmq01_commands.md](commands/rmq01_commands.md). Skip `dnf update`. Swap and password SSH already come from the template.

`rmq01` deployed. Public IP `20.85.239.154`, private `172.16.0.6`, VNet `vnet-eastus-1`. RabbitMQ commands are done.

## Step 5 — Create `app01` (now)

Same template `deploy/vm.json`. **Change size** — Tomcat + Maven need more RAM.

| Parameter | Value |
|---|---|
| Resource group | `vprofile` |
| vmName | `app01` |
| vmSize | **`Standard_B2s`** |
| vnetName | `vnet-eastus-1` |
| adminPassword | same `azureuser` password |

`app01` is Running. Public IP `20.85.229.239`, private `172.16.0.7`, size `Standard_B2s`.

Then [commands/app01_commands.md](commands/app01_commands.md). After Tomcat is up, add NSG inbound **8080** on `app01` and open `http://20.85.229.239:8080`.
