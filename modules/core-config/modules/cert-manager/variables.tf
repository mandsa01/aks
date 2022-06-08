variable "azure_environment" {
  description = "Azure Cloud Environment."
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

variable "dns_resource_group_lookup" {
  description = "Lookup from DNS zone to resource group name."
  type        = map(string)
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "acme_dns_zones" {
  description = "DNS zones which can be managed via the ACME protocol."
  type        = list(string)
}

variable "additional_issuers" {
  description = "Additional issuers to add to the cluster."
  type        = map(any)
}

variable "default_issuer_kind" {
  description = "The default issuer kind."
  type        = string
}

variable "default_issuer_name" {
  description = "The default issuer."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
