# Task 2 — One deployment, four VMs, Custom data

Same stack as Task 1. One file creates the VNet and all four VMs. Each VM’s **Custom data** is the install script (AWS User data). You do not SSH in to run `dnf` by hand.

**Portal file:** [deploy/vprofile.json](deploy/vprofile.json)

Readable source: [deploy/vprofile.bicep](deploy/vprofile.bicep) loads [scripts/](scripts/). After you edit a `.sh` file, rebuild JSON:

```powershell
az bicep build --file deploy/vprofile.bicep --outfile deploy/vprofile.json
```

## What the file creates

| VM | Size | Custom data | Public inbound |
|---|---|---|---|
| `db01` | `Standard_B1s` | MariaDB, `accounts` DB, SQL dump | SSH 22 |
| `mc01` | `Standard_B1s` | Memcached on `0.0.0.0` | SSH 22 |
| `rmq01` | `Standard_B1s` | RabbitMQ user `test` / `test` | SSH 22 |
| `app01` | `Standard_B2s` | Java 11, Tomcat, Maven WAR | SSH 22 + **8080** |

All on `vnet-eastus-1` / `snet-eastus-1` (`172.16.0.0/24`). Image: CentOS Stream 9 Gen2 (ProComputers). SSH user: `azureuser`.

## Portal (no CLI MFA)

1. Create an empty resource group **`vprofile`** in **East US** (the old one was deleted).
2. Open [portal.azure.com](https://portal.azure.com) → search **Deploy a custom template**.
3. **Build your own template in the editor** → **Load file** → pick `deploy/vprofile.json`.
4. **Save**.
5. Subscription: **Azure Sponsorship**. Resource group: **`vprofile`**. Region: **East US**.
6. **adminPassword:** the `azureuser` password (only required field).
7. **Review + create**. Accept the ProComputers marketplace terms if asked.

Azure reports the deployment **Succeeded** when the four VMs exist. Custom data keeps running after that.

| VM | Wait after VM is Running |
|---|---|
| `db01` / `mc01` / `rmq01` | about 5–10 minutes |
| `app01` | about 15–25 minutes (Maven) |

```bash
ssh azureuser@<public-ip>
sudo tail -f /var/log/vprofile-customdata.log
```

When `app01` log says `app01 custom data done`, open the deployment **Outputs** `appUrl`, or `http://<app01-public-ip>:8080` (`admin_vp` / `admin_vp`).

## This run (worked)

Live log: [progress.md](progress.md). App: [http://168.62.61.151:8080](http://168.62.61.151:8080).

```bash
ssh azureuser@20.85.215.10    # db01
ssh azureuser@20.102.55.91    # mc01
ssh azureuser@20.115.2.194    # rmq01
ssh azureuser@168.62.61.151   # app01
```

```bash
sudo tail -f /var/log/vprofile-customdata.log
```

## After the lab

Delete resource group `vprofile` so you are not billed. Recreate anytime with the same JSON.
