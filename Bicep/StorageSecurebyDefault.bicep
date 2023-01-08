
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "metadata": {
    "_generator": {
      "name": "bicep",
      "version": "0.4.1124.51302",
      "templateHash": "16766334222894722560"
    }
  },
  "parameters": {
    "Storagename": {
      "type": "string"
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]"
    },
    "accesstier": {
      "type": "string"
    },
    "subnetid": {
      "type": "string"
    },
    "SKU": {
      "type": "string"
    }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-06-01",
      "name": "[parameters('Storagename')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "[parameters('SKU')]"
      },
      "kind": "StorageV2",
      "properties": {
        "allowBlobPublicAccess": false,
        "minimumTlsVersion": "TLS1_2",
        "supportsHttpsTrafficOnly": true,
        "defaultToOAuthAuthentication": true,
        "allowSharedKeyAccess": false,
        "accessTier": "[parameters('accesstier')]",
        "networkAcls": {
          "defaultAction": "Deny",
          "bypass": "AzureServices"
        }
      }
    },
    {
      "type": "Microsoft.Network/privateEndpoints",
      "apiVersion": "2021-05-01",
      "name": "[format('{0}-plink', parameters('Storagename'))]",
      "location": "[parameters('location')]",
      "properties": {
        "subnet": {
          "id": "[parameters('subnetid')]"
        },
        "privateLinkServiceConnections": [
          {
            "name": "[format('{0}-plink', parameters('Storagename'))]",
            "properties": {
              "privateLinkServiceId": "[resourceId('Microsoft.Storage/storageAccounts', parameters('Storagename'))]",
              "groupIds": [
                "Blob"
              ]
            }
          }
        ]
      },
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('Storagename'))]"
      ]
    }
  ]
}
