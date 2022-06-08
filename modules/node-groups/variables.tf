variable "subscription_id" {
  description = "ID of the subscription being used."
  type        = string
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "cluster_id" {
  description = "ID of the Azure Kubernetes managed cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster."
  type        = string
}

variable "cluster_version_full" {
  description = "The full Kubernetes version of the Azure Kubernetes managed cluster."
  type        = string
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin, \"kubenet\" & \"azure\" are supported."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to use for the node groups."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to use for the node groups."
  type        = list(number)
}

variable "node_group_templates" {
  description = "Node group templates to be expanded."
  type = list(object({
    name                = string
    node_os             = string
    node_type           = string
    node_type_version   = string
    node_size           = string
    single_group        = bool
    min_capacity        = number
    max_capacity        = number
    placement_group_key = string
    labels              = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags = map(string)
  }))
}

variable "bootstrap_name" {
  description = "Name to use for the bootstrap node group."
  type        = string
}

variable "bootstrap_vm_size" {
  description = "VM size to use for the bootstrap node group."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}

# tflint-ignore: terraform_unused_declarations
variable "experimental" {
  description = "Provide experimental feature flag configuration."
  type        = any
}
