@description('Region. Must match the resource group.')
param location string

@description('Linux admin user.')
param adminUsername string

@secure()
param adminPassword string

var vnetName = 'vnet-vprofile-k8s'
var subnetName = 'snet-vprofile-k8s'
var nsgName = 'nsg-vprofile-k8s'
var acrName = 'acrvprofilel8'
var vnetPrefix = '10.10.0.0/16'
var subnetPrefix = '10.10.1.0/24'

var vms = [
  {
    name: 'vm-vprofile-master'
    nicName: 'nic-vprofile-master'
    pipName: 'pip-vprofile-master'
    size: 'Standard_B2ms'
  }
  {
    name: 'vm-vprofile-worker'
    nicName: 'nic-vprofile-worker'
    pipName: 'pip-vprofile-worker'
    size: 'Standard_D4s_v5'
  }
]

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'allow-k8s-api'
        properties: {
          priority: 1010
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '6443'
        }
      }
      {
        name: 'allow-nodeport-app'
        properties: {
          priority: 1020
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '30080'
        }
      }
      {
        name: 'allow-nodeport-argocd'
        properties: {
          priority: 1030
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '30081'
        }
      }
      {
        name: 'allow-nodeport-jenkins'
        properties: {
          priority: 1040
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '30082'
        }
      }
      {
        name: 'allow-nodeport-grafana'
        properties: {
          priority: 1050
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '30083'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = [for vm in vms: {
  name: vm.pipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = [for (vm, i) in vms: {
  name: vm.nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          publicIPAddress: {
            id: pip[i].id
          }
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = [for (item, i) in vms: {
  name: item.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: item.size
    }
    osProfile: {
      computerName: item.name
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: '${item.name}-osdisk'
        createOption: 'FromImage'
        diskSizeGB: 64
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
  }
}]

output acrLoginServer string = acr.properties.loginServer
output masterPublicIp string = pip[0].properties.ipAddress
output workerPublicIp string = pip[1].properties.ipAddress
