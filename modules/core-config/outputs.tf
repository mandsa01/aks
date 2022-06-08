output "cert_manager_identity" {
  description = "Identity that Cert Manager uses."
  value       = module.cert_manager.identity
}

output "external_dns_private_identity" {
  description = "Identity that private ExternalDNS uses."
  value       = module.external_dns.private_identity
}

output "external_dns_public_identity" {
  description = "Identity that public ExternalDNS uses."
  value       = module.external_dns.public_identity
}

output "fluentd_identity" {
  description = "Identity that Fluentd uses."
  value       = module.fluentd.identity
}

output "grafana_identity" {
  description = "Identity that Grafana uses."
  value       = module.kube_prometheus_stack.grafana_identity
}
