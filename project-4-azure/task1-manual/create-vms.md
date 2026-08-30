# Create the 4 VMs (Azure portal)

Do this four times. Only the **name** changes. Everything else stays the same.

Create them in this order: `db01` → `mc01` → `rmq01` → `app01`.

## Once, before the first VM

1. Open [portal.azure.com](https://portal.azure.com).
2. Resource group is already created: **`vprofile`** in **East US**.
3. When the first VM asks for an SSH key, choose **Generate new key pair**. Download the `.pem`. Keep it. You will reuse this key on the other three VMs.

## Every VM — Basics tab

| Field | Value |
|---|---|
| Resource group | `vprofile` (same for all four) |
| Virtual machine name | `db01` / `mc01` / `rmq01` / `app01` (exact names) |
| Region | East US (`eastus`) — same as the group |
| Image | search **CentOS Stream 9** — publisher **ProComputers**. Prefer the **Gen2** plan (`centos-stream-9-gen2`). Not Ubuntu, not Rocky, not Alma, not OpenLogic CentOS 7. |
| Size | `Standard_B1s` for `db01`, `mc01`, `rmq01`. `Standard_B2s` for `app01` (Maven + Tomcat) |
| Authentication | SSH public key |
| Username | `azureuser` |
| SSH key | the key you generated on the first VM |
| Public inbound ports | SSH (22) |

Leave **Networking** as Azure fills it (default VNet / subnet / public IP / NSG). That is “he left the network as it is.”

Leave **Advanced → Custom data** empty. That is Task 2.

Click **Review + create**, then **Create**. Wait until the VM is Running.

## After each VM is up

1. Open the VM → **Overview**.
2. Copy **Public IP address**.
3. SSH in (see [README.md](README.md)).
4. Confirm the OS before you install anything:

```bash
cat /etc/os-release
```

You want `CentOS Stream` and `9`. If you see Ubuntu or Rocky, delete that VM and recreate it with the CentOS Stream 9 image.

## After all four exist

You will have four public IPs. You only need the `app01` one in the browser later. Use the others only for SSH.

Do not open 3306 / 11211 / 5672 to the internet. VMs in the same VNet can already reach each other.

When Tomcat is running, on the `app01` NSG add an inbound rule: TCP **8080**, source Any (lab only).
