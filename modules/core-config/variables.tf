variable "azure_env" {
  description = "Azure cloud environment type."
  type        = string
}

variable "tenant_id" {
  description = "ID of the Azure Tenant."
  type        = string
}

variable "subscription_id" {
  description = "ID of the subscription."
  type        = string
}

variable "location" {
  description = "Azure region in which the AKS cluster is located."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version of the AKS cluster."
  type        = string
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin."
  type        = string
}

variable "subnet_name" {
  description = "name of the node group subnet."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to use for the node groups."
  type        = list(number)
}

variable "kubelet_identity_id" {
  description = "ID of the Kubelet identity."
  type        = string
}

variable "node_resource_group_name" {
  description = "Name of the node resource group."
  type        = string
}

variable "dns_resource_group_lookup" {
  description = "Lookup from DNS zone to resource group name."
  type        = map(string)
}

variable "core_services_config" {
  description = "Core configuration options."
  type        = any
}

variable "control_plane_log_analytics_workspace_id" {
  description = "ID of the log analytics workspace for the AKS cluster control plane."
  type        = string
}

variable "oms_agent" {
  description = "If the OMS agent addon should be installed."
  type        = bool
}

variable "oms_log_analytics_workspace_id" {
  description = "ID of the log analytics workspace for the OMS agent."
  type        = string
}

variable "oms_log_analytics_workspace_different_resource_group" {
  description = "If the oms agent log analytics workspace is in a different resource group to the cluster."
  type        = bool
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
}

# tflint-ignore: terraform_unused_declarations
variable "experimental" {
  description = "Provide experimental feature flag configuration."
  type        = any
}
