variable "subscription_id" {
  description = "ID of the subscription being used."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to use for the bootstrap node group."
  type        = string
}

variable "bootstrap_name" {
  description = "Name to use for the bootstrap node group."
  type        = string
}

variable "bootstrap_vm_size" {
  description = "VM size to use for the bootstrap node group."
  type        = string
}
