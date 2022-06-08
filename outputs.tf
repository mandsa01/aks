output "cluster_id" {
  description = "Azure Kubernetes Service (AKS) managed cluster ID."
  value       = module.cluster.id
}

output "cluster_fqdn" {
  description = "FQDN of the Azure Kubernetes Service managed cluster."
  value       = module.cluster.fqdn
}

output "cluster_endpoint" {
  description = "Endpoint for the Azure Kubernetes Service managed cluster API server."
  value       = module.cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the Azure Kubernetes Service managed cluster API server."
  value       = module.cluster.certificate_authority_data
}

output "control_plane_log_analytics_workspace_id" {
  description = "ID of the default log analytics workspace created for control plane logs."
  value       = module.cluster.control_plane_log_analytics_workspace_id
}

output "control_plane_log_analytics_workspace_name" {
  description = "Name of the default log analytics workspace created for control plane logs."
  value       = module.cluster.control_plane_log_analytics_workspace_id
}

output "node_resource_group_name" {
  description = "Auto-generated resource group which contains the resources for this managed Kubernetes cluster."
  value       = module.cluster.node_resource_group_name
}

output "effective_outbound_ips" {
  description = "Outbound IPs from the Azure Kubernetes Service managed cluster."
  value       = module.cluster.effective_outbound_ips
}

output "cluster_identity" {
  description = "User assigned identity used by the cluster."
  value       = module.cluster.cluster_identity
}

output "kubelet_identity" {
  description = "Kubelet identity."
  value       = module.cluster.kubelet_identity
}

output "cert_manager_identity" {
  description = "Identity that Cert Manager uses."
  value       = module.core_config.cert_manager_identity
}

output "external_dns_private_identity" {
  description = "Identity that private ExternalDNS uses."
  value       = module.core_config.external_dns_private_identity
}

output "external_dns_public_identity" {
  description = "Identity that public ExternalDNS uses."
  value       = module.core_config.external_dns_public_identity
}

output "fluentd_identity" {
  description = "Identity that Fluentd uses."
  value       = module.core_config.fluentd_identity
}

output "grafana_identity" {
  description = "Identity that Grafana uses."
  value       = module.core_config.grafana_identity
}

output "oms_agent_identity" {
  description = "Identity that the OMS agent uses."
  value       = module.cluster.oms_agent_identity
}

output "windows_config" {
  description = "Windows configuration."
  value       = module.cluster.windows_config
}
