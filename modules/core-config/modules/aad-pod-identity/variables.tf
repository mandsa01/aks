variable "subscription_id" {
  description = "ID of the subscription."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the main resource group."
  type        = string
}

variable "node_resource_group_name" {
  description = "Name of the resource group containing the nodes."
  type        = string
}

variable "network_plugin" {
  description = "Kubernetes network plugin."
  type        = string
}

variable "kubelet_identity_id" {
  description = "ID of the Kubelet identity."
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

variable "experimental" {
  description = "Provide experimental feature flag configuration."
  type        = any
}
