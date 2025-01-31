param webAppName string
param planName string
param keyVaultName string
param sqlServerName string
@secure()
param sqlAdminPassword string 
param sqlAdminUsername string = 'azureuser'

param location string = resourceGroup().location

resource plan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: planName
  location: location
  sku: {
    name: 'F1'
    capacity: 1
  }
  properties: {}
}

resource webApp 'Microsoft.Web/sites@2020-12-01' = {
  name: webAppName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${planName}': 'Resource'
    displayName: webAppName
  }
  properties: {
    serverFarmId: plan.id
    keyVaultReferenceIdentity: appIdentity.id
  }

  resource settings 'config' = {
    name: 'appsettings'
    properties: {
      connectionString: '@Microsoft.KeyVault(SecretUri=${keyVault::connectionStringSecret.properties.secretUri})'
    }
  }

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appIdentity.id}': {}
    }
  }
}

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'app-identity'
  location: location
}

resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
  }
}

var connectionString = 'Server=tcp:${sqlServer.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=master;Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;'

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: appIdentity.properties.principalId
        permissions: {
          secrets: [
            'list'
            'get'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }

  resource connectionStringSecret 'secrets' = {
    name: 'connectionString'
    properties: {
      value: connectionString
    }
  }
}
