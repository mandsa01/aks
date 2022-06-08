variable "name" {
  description = "Name of the node group being created."
  type        = string
}

variable "cluster_id" {
  description = "ID of the Azure Kubernetes managed cluster."
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
  description = "ID of the subnet to use for the node group."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to use for the node group."
  type        = list(number)
}

variable "system" {
  description = "If the node group is of the system or user mode."
  type        = bool
}

variable "min_capacity" {
  description = "Minimum number of nodes in the group."
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of nodes in the group."
  type        = number
}

variable "node_os" {
  description = "The OS to use for the nodes, \"ubuntu\" & \"windows\" are supported."
  type        = string
}

variable "node_type" {
  description = "The type of nodes to create, \"gp\", \"gpd\", \"mem\", \"memd\" & \"stor\" are supported."
  type        = string
}

variable "node_type_version" {
  description = "Version of the node type to use."
  type        = string
}

variable "node_size" {
  description = "The size of nodes to create."
  type        = string
}

variable "proximity_placement_group_id" {
  description = "Proximity placement group ID to use if set."
  type        = string
}

variable "labels" {
  description = "Labels to set on the nodes."
  type        = map(string)
}

variable "taints" {
  description = "Taints to set on the nodes."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}
