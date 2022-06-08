output "private_identity" {
  description = "Identity that private ExternalDNS uses."
  value       = module.identity_private
}

output "public_identity" {
  description = "Identity that public ExternalDNS uses."
  value       = module.identity_public
}
