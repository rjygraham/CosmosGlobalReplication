targetScope = 'resourceGroup'

param regions array
param namePrefix string

var cosmosDbName = '${namePrefix}-cosmosdb'
var cosmosDatabaseName = 'Global'
var cosmosContainerName = 'Messages'
var location = regions[0].location

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' = {
  name: cosmosDbName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
    enableMultipleWriteLocations: true
    locations: [for (region, i) in regions: {
      failoverPriority: i
      isZoneRedundant: false
      locationName: region.location
    }]
  }

  resource database 'sqlDatabases' = {
    name: cosmosDatabaseName
    location: location
    properties: {
      options: {
        autoscaleSettings: {
          maxThroughput: 1000
        }
      }
      resource: {
        id: cosmosDatabaseName
      }
    }

    resource leases 'containers' = {
      name: cosmosContainerName
      properties: {
        resource: {
          id: cosmosContainerName
          partitionKey: {
            paths: [
              '/id'
            ]
            kind: 'Hash'
          }
        }
      }
    }
  }
}

output sharedCosmosDbName string = cosmosDb.name
