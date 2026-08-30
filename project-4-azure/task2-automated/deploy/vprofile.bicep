@description('Password for azureuser on all four VMs. Azure complexity rules apply.')
@secure()
param adminPassword string

@description('Linux admin user')
param adminUsername string = 'azureuser'

@description('Same region as Task 1')
param location string = 'eastus'

@description('Existing-style names so Azure DNS still answers db01 / mc01 / rmq01 / app01')
param vnetName string = 'vnet-eastus-1'
param subnetName string = 'snet-eastus-1'
param vnetPrefix string = '172.16.0.0/24'

var db01Script = loadTextContent('../scripts/db01.sh')
var mc01Script = loadTextContent('../scripts/mc01.sh')
var rmq01Script = loadTextContent('../scripts/rmq01.sh')
var app01Script = loadTextContent('../scripts/app01.sh')

var vms = [
  {
    name: 'db01'
    size: 'Standard_B1s'
    allowHttp8080: false
    script: db01Script
  }
  {
    name: 'mc01'
    size: 'Standard_B1s'
    allowHttp8080: false
    script: mc01Script
  }
  {
    name: 'rmq01'
    size: 'Standard_B1s'
    allowHttp8080: false
    script: rmq01Script
  }
  {
    name: 'app01'
    size: 'Standard_B2s'
    allowHttp8080: true
    script: app01Script
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetPrefix]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: vnetPrefix
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = [for vm in vms: {
  name: '${vm.name}-nsg'
  location: location
  properties: {
    securityRules: concat(
      [
        {
          name: 'SSH'
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
      ],
      vm.allowHttp8080
        ? [
            {
              name: 'allow-8080'
              properties: {
                priority: 1010
                protocol: 'Tcp'
                access: 'Allow'
                direction: 'Inbound'
                sourceAddressPrefix: '*'
                sourcePortRange: '*'
                destinationAddressPrefix: '*'
                destinationPortRange: '8080'
              }
            }
          ]
        : []
    )
  }
}]

resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = [for vm in vms: {
  name: '${vm.name}-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = [for (vm, i) in vms: {
  name: '${vm.name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetName)
          }
          publicIPAddress: {
            id: pip[i].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg[i].id
    }
  }
}]

resource vmRes 'Microsoft.Compute/virtualMachines@2024-03-01' = [for (vm, i) in vms: {
  name: vm.name
  location: location
  plan: {
    name: 'centos-stream-9-gen2'
    product: 'centos-stream-9-gen2'
    publisher: 'procomputers'
  }
  properties: {
    hardwareProfile: {
      vmSize: vm.size
    }
    osProfile: {
      computerName: vm.name
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(vm.script)
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'procomputers'
        offer: 'centos-stream-9-gen2'
        sku: 'centos-stream-9-gen2'
        version: 'latest'
      }
      osDisk: {
        name: '${vm.name}-osdisk'
        createOption: 'FromImage'
        diskSizeGB: 30
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}]

output publicIps object = {
  db01: pip[0].properties.ipAddress
  mc01: pip[1].properties.ipAddress
  rmq01: pip[2].properties.ipAddress
  app01: pip[3].properties.ipAddress
}

output privateIps object = {
  db01: nic[0].properties.ipConfigurations[0].properties.privateIPAddress
  mc01: nic[1].properties.ipConfigurations[0].properties.privateIPAddress
  rmq01: nic[2].properties.ipConfigurations[0].properties.privateIPAddress
  app01: nic[3].properties.ipConfigurations[0].properties.privateIPAddress
}

output appUrl string = 'http://${pip[3].properties.ipAddress}:8080'
