targetScope = 'subscription'

@description('Region. Lecture 4 used eastus.')
param location string = 'eastus'

@description('Linux admin user. Password is passed at deploy time and is not stored in this file.')
param adminUsername string = 'azureuser'

@secure()
@description('Password for azureuser. Azure requires 12+ characters and 3 of: upper, lower, digit, symbol.')
param adminPassword string

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-vprofile-k8s'
  location: location
}

module cluster 'cluster.bicep' = {
  name: 'vprofile-k8s'
  scope: rg
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

output resourceGroupName string = rg.name
output acrLoginServer string = cluster.outputs.acrLoginServer
output masterPublicIp string = cluster.outputs.masterPublicIp
output workerPublicIp string = cluster.outputs.workerPublicIp
