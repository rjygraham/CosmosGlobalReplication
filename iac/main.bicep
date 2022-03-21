targetScope = 'subscription'

param regions array = [
  {
    location: 'eastus'
    abbreviation: 'eus'
  }
  {
    location: 'westus3'
    abbreviation: 'wus3'
  }
  {
    location: 'westeurope'
    abbreviation: 'weu'
  }
]

param namePrefix string = 'a${substring(uniqueString(subscription().subscriptionId), 0, 9)}'

module sharedDeployment 'modules/sharedResourceGroup.bicep' = {
  name: 'shared'
  params: {
    regions: regions
    namePrefix: '${namePrefix}-shared'
  }
}

module regionDeploymnent 'modules/regionResourceGroup.bicep' = [for region in regions: {
  name: '${region.location}'
  params: {
    location: region.location
    namePrefix: '${namePrefix}-${region.abbreviation}'
    sharedResourceGroupName: sharedDeployment.outputs.sharedResourceGroupName
    sharedCosmosDbName: sharedDeployment.outputs.sharedCosmosDbName
  }
}]

output config array = [for (region, i) in regions: {
  name: region.location
  config: regionDeploymnent[i].outputs.regionConfig
}]
