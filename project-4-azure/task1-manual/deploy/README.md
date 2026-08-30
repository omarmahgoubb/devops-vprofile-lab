# Reusable VM (same as db01)

Creates one CentOS Stream 9 Gen2 VM on the **existing** VNet `vnet-eastus-1`. Same size and disk as `db01` unless you change `vmSize`.

First-boot script: enable password SSH + 2G swap.

## What you change

| VM | `vmName` | `vmSize` |
|---|---|---|
| Memcached | `mc01` | `Standard_B1s` |
| RabbitMQ | `rmq01` | `Standard_B1s` |
| Tomcat | `app01` | `Standard_B2s` |

Leave `vnetName` = `vnet-eastus-1`. Do not create a new VNet.

## Portal (no CLI MFA)

1. Open [portal.azure.com](https://portal.azure.com) (you are already MFA’d in the browser).
2. Search **Deploy a custom template**.
3. **Build your own template in the editor**.
4. **Load file** → pick `vm.json` from this folder.
5. **Save**.
6. Subscription: **Azure Sponsorship**. Resource group: **`vprofile`**.
7. Region: **East US**.
8. **vmName:** `mc01` (later `rmq01`, then `app01`).
9. **adminPassword:** your `azureuser` password.
10. **vmSize:** `Standard_B1s` (`Standard_B2s` only for `app01`).
11. **Review + create**. Accept the ProComputers marketplace terms if asked.

Wait until the deployment succeeds. Copy the public IP from the VM **Overview**.

```bash
ssh azureuser@<public-ip>
```

Wait ~1 minute after the VM is Running so custom data can enable password SSH and swap.

Then run the matching file in `../commands/` (`mc01_commands.md`, and so on). Skip `dnf update` on B1s.

## Cloud Shell (if you prefer CLI)

```bash
az vm image terms accept --publisher procomputers --offer centos-stream-9-gen2 --plan centos-stream-9-gen2

az deployment group create \
  --resource-group vprofile \
  --template-file vm.json \
  --parameters vmName=mc01 vmSize=Standard_B1s
```

It will prompt for `adminPassword`.
