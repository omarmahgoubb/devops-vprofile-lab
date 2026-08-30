# Recreate mc01 to match db01: B1s, Standard SSD 30 GiB, CentOS Stream 9 Gen2, vnet-eastus-1.
# First, in this same window:
#   az logout
#   az login --tenant "63af7b8c-ba1b-45ab-bcb7-7aeb74091783" --scope "https://management.core.windows.net//.default"
# Complete MFA in the browser, then run this script.

$ErrorActionPreference = "Continue"

az vm delete --resource-group vprofile --name mc01 --yes --force-deletion true 2>$null

az vm image terms accept --publisher procomputers --offer centos-stream-9-gen2 --plan centos-stream-9-gen2

az vm create `
  --resource-group vprofile `
  --name mc01 `
  --location eastus `
  --image procomputers:centos-stream-9-gen2:centos-stream-9-gen2:latest `
  --plan-name centos-stream-9-gen2 `
  --plan-product centos-stream-9-gen2 `
  --plan-publisher procomputers `
  --size Standard_B1s `
  --vnet-name vnet-eastus-1 `
  --subnet snet-eastus-1 `
  --public-ip-sku Standard `
  --nsg-rule SSH `
  --admin-username azureuser `
  --generate-ssh-keys `
  --storage-sku StandardSSD_LRS `
  --os-disk-size-gb 30

az vm boot-diagnostics disable --resource-group vprofile --name mc01

az vm run-command invoke --resource-group vprofile --name mc01 --command-id RunShellScript --scripts "sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/01-localconfig.conf; systemctl restart sshd"

az vm list --resource-group vprofile -d --query "[].{Name:name, Power:powerState, PublicIP:publicIps, PrivateIP:privateIps}" -o table
