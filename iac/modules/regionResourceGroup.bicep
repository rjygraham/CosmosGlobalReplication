targetScope = 'subscription'

param location string
param namePrefix string
param sharedResourceGroupName string
param sharedCosmosDbName string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: toUpper(namePrefix)
  location: location
}

module resources 'regionResources.bicep' = {
  name: toLower('${resourceGroup.name}-resources')
  scope: resourceGroup
  params: {
    location: location
    namePrefix: namePrefix
    sharedResourceGroupName: sharedResourceGroupName
    sharedCosmosDbName: sharedCosmosDbName
  }
}

output regionConfig object = {
  url: resources.outputs.functionAppUrl
  key: resources.outputs.functionAppKey
}
