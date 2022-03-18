targetScope = 'resourceGroup'

param location string
param namePrefix string

param sharedResourceGroupName string
param sharedCosmosDbName string

var signalRName = '${namePrefix}-sigr'
var logAnalyticsWorkspaceName = '${namePrefix}-law'
var appInsightsName = '${namePrefix}-ai'

var storageAccountName = toLower(replace('${namePrefix}-stg', '-', ''))
var serverFarmName = '${namePrefix}-asp'
var functionName = '${namePrefix}-func'

var cosmosDbName = '${namePrefix}-cosmosdb'
var cosmosDbDatabaseName = 'Local'
var cosmosDbContainerName = 'Leases'

resource sharedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: sharedResourceGroupName
  scope: subscription()
}

resource sharedCosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' existing = {
  name: sharedCosmosDbName
  scope: sharedResourceGroup
}

resource signalR 'Microsoft.SignalRService/signalR@2021-10-01' = {
  name: signalRName
  location: location
  sku: {
    name: 'Free_F1'
    tier: 'Free'
  }
  properties: {
    features: [
      {
        flag: 'ServiceMode'
        value: 'Serverless'
      }
      {
        flag: 'EnableConnectivityLogs'
        value: 'true'
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
    tls: {
      clientCertEnabled: false
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: serverFarmName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
  }
  kind: 'functionapp'
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionName
  location: location
  kind: 'functionapp,linux'
  properties: {
    reserved: true
    serverFarmId: serverFarm.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'origin'
          value: location
        }
        {
          name: 'AzureSignalRConnectionString'
          value: signalR.listKeys().primaryConnectionString
        }
        {
          name: 'CosmosDbGlobalConnectionString'
          value: sharedCosmosDb.listConnectionStrings().connectionStrings[0].connectionString
        }
        {
          name: 'CosmosDbLocalConnectionString'
          value: cosmosDb.listConnectionStrings().connectionStrings[0].connectionString
        }
        {
          name: 'AzureWebJobs.CreateRecord.Disabled'
          value: '1'
        }
      ]
    }
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' = {
  name: cosmosDbName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: location
      }
    ]
  }

  resource database 'sqlDatabases' = {
    name: cosmosDbDatabaseName
    location: location
    properties: {
      options: {
        throughput: 400
      }
      resource: {
        id: cosmosDbDatabaseName
      }
    }

    resource leases 'containers' = {
      name: cosmosDbContainerName
      properties: {
        resource: {
          id: cosmosDbContainerName
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

output functionAppUrl string = functionApp.properties.hostNames[0]
#disable-next-line outputs-should-not-contain-secrets
output functionAppKey string = functionApp.listsyncfunctiontriggerstatus().key
