output "id" {
  description = "ID of user assigned identity."
  value       = azurerm_user_assigned_identity.default.id
}

output "name" {
  description = "Name of user assigned identity."
  value       = azurerm_user_assigned_identity.default.name
}

output "principal_id" {
  description = "Service Principal ID of user assigned identity."
  value       = azurerm_user_assigned_identity.default.principal_id
}

output "client_id" {
  description = "Client ID of user assigned identity."
  value       = azurerm_user_assigned_identity.default.client_id
}
