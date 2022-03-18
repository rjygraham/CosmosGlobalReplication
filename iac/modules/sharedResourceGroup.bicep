targetScope = 'subscription'

param regions array
param namePrefix string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: toUpper(namePrefix)
  location: regions[0].location
}

module resources 'sharedResources.bicep' = {
  name: toLower('${resourceGroup.name}-resources')
  scope: resourceGroup
  params: {
    regions: regions
    namePrefix: namePrefix
  }
}

output sharedResourceGroupName string = resourceGroup.name
output sharedCosmosDbName string = resources.outputs.sharedCosmosDbName
