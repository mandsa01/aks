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

variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "zones" {
  description = "The number of zones this chart should be run on."
  type        = number
}

variable "prometheus_remote_write" {
  description = "Remote Prometheus endpoints to write metrics to."
  type        = list(any)
}

variable "alertmanager_smtp_host" {
  description = "The SMTP host to use for Alert Manager."
  type        = string
}

variable "alertmanager_smtp_from" {
  description = "The SMTP from address to use for Alert Manager."
  type        = string
}

variable "alertmanager_receivers" {
  description = "Alertmanager recievers to add to the default null, will always be a list."
  type        = any
}

variable "alertmanager_routes" {
  description = "Alertmanager routes, will always be a list."
  type        = any
}

variable "grafana_admin_password" {
  description = "The Grafana admin password."
  type        = string
}

variable "grafana_additional_plugins" {
  description = "Additional Grafana plugins to install."
  type        = list(string)
}

variable "grafana_additional_data_sources" {
  description = "Additional Grafana data sources to add."
  type        = list(any)
}

variable "ingress_class_name" {
  description = "The ingress class for ingress resources."
  type        = string
}

variable "ingress_domain" {
  description = "The domain to use for ingress resources."
  type        = string
}

variable "ingress_subdomain_suffix" {
  description = "The suffix for the ingress subdomain."
  type        = string
}

variable "ingress_annotations" {
  description = "The annotations for ingress resources."
  type        = map(string)
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

variable "skip_crds" {
  description = "Skip installing the CRDs as part of the module."
  type        = bool
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
