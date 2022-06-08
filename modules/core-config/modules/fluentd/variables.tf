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

variable "image_repository" {
  description = "Custom image repository to use for the Fluentd image, image_tag must also be set."
  type        = string
}

variable "image_tag" {
  description = "Custom image tag to use for the Fluentd image, image_repository must also be set."
  type        = string
}

variable "additional_env" {
  description = "Additional environment variables."
  type        = map(string)
}

variable "debug" {
  description = "If Fluentd should write all processed log entries to stdout."
  type        = bool
}

variable "filters" {
  description = "The filter config split into multiple strings."
  type        = string
}

variable "routes" {
  description = "The route config, split into multiple strings."
  type        = string
}

variable "outputs" {
  description = "The output config, split into multiple strings."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
