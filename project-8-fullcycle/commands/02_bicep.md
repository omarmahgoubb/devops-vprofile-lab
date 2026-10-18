# 02 — Bicep deployed

Files: `bicep/main.bicep` creates the resource group and calls `bicep/cluster.bicep`, which creates everything inside the group. `az bicep build` compiled `main.bicep` with no errors. Do not run the deploy command until you mean to pay for the VMs, the disks, the two public IPs, and ACR Basic.

## What the file creates

| Name | Resource |
|---|---|
| `rg-vprofile-k8s` | Resource group, `eastus` |
| `vnet-vprofile-k8s` | VNet `10.10.0.0/16` |
| `snet-vprofile-k8s` | Subnet `10.10.1.0/24` |
| `nsg-vprofile-k8s` | Inbound TCP 22, 6443, 30080, 30081, 30082 |
| `vm-vprofile-master` | Ubuntu 22.04, `Standard_B2ms`, 64 GB Standard SSD |
| `vm-vprofile-worker` | Ubuntu 22.04, `Standard_D4s_v5`, 64 GB Standard SSD |
| `nic-vprofile-master`, `nic-vprofile-worker` | One NIC each |
| `pip-vprofile-master`, `pip-vprofile-worker` | Standard public IP, static |
| `acrvprofilel8` | ACR Basic, admin user enabled |
| `vm-vprofile-master-osdisk`, `vm-vprofile-worker-osdisk` | OS disks |

Lecture 4's resource group `vprofile` is not used.

Linux user is `azureuser`. The password is a secure parameter. It is not in the file.

## Public IP change from the name list

The name list said dynamic public IPs. Basic public IPs are retired, and a Standard public IP must be static. A static IP keeps billing after the VM is deallocated. Delete the IP, or the whole resource group, to stop that charge. Deallocating the VM stops the compute charge only.

## Deploy

Local `az login` could read the subscription, but `az deployment sub create` returned `AADSTS50076` (MFA required for Azure Resource Manager). A second `az login` still did not satisfy that claim. The deploy was run from Azure Cloud Shell after uploading `main.bicep` and `cluster.bicep` to the Cloud Shell home directory.

```powershell
az deployment sub create --location eastus --template-file main.bicep --parameters adminPassword='YOUR_PASSWORD'
```

The password is not stored in this repo.

Result: provisioning state **Succeeded**. Duration about 1 minute 47 seconds. Subscription `Azure Sponsership` (`243d1c50-1d8c-429f-9dc4-c939f6c0adad`). Timestamp `2026-10-17T23:39:52Z`. Deployment name `main`.

| Output | Value |
|---|---|
| Resource group | `rg-vprofile-k8s` |
| Master public IP | `40.87.97.146` |
| Worker public IP | `23.100.22.38` |
| ACR login server | `acrvprofilel8.azurecr.io` |
| Linux user | `azureuser` |

ACR admin password is created by Azure. Read it later with `az acr credential show --name acrvprofilel8`. Do not commit it.
