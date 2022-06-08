locals {
  azure_identity = {
    apiVersion = "aadpodidentity.k8s.io/v1"
    kind       = "AzureIdentity"
    metadata = {
      name      = azurerm_user_assigned_identity.default.name
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      type       = 0
      resourceID = azurerm_user_assigned_identity.default.id
      clientID   = azurerm_user_assigned_identity.default.client_id
    }
  }

  azure_identity_binding = {
    apiVersion = "aadpodidentity.k8s.io/v1"
    kind       = "AzureIdentityBinding"
    metadata = {
      name      = "${azurerm_user_assigned_identity.default.name}-binding"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      azureIdentity = azurerm_user_assigned_identity.default.name
      selector      = azurerm_user_assigned_identity.default.name
    }
  }
}
