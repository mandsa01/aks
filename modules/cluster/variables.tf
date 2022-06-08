variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster to create, also used as a prefix in names of related resources."
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

variable "sku_tier_paid" {
  description = "If the cluster control plane SKU tier should be paid or free. The paid tier has a financially-backed uptime SLA."
  type        = bool
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Azure Kubernetes managed cluster public API server endpoint is enabled."
  type        = bool
}

variable "cluster_endpoint_access_cidrs" {
  description = "List of CIDR blocks which can access the Azure Kubernetes managed cluster API server endpoint."
  type        = list(string)
}

variable "subnet_id" {
  description = "ID of the subnet."
  type        = string
}

variable "route_table_id" {
  description = "ID of the route table."
  type        = string
}

variable "podnet_cidr_block" {
  description = "CIDR range for pod IP addresses when using the kubenet network plugin."
  type        = string
}

variable "admin_group_object_ids" {
  description = "AD Object IDs to be added to the cluster admin group, if not set the current user will be made a cluster administrator."
  type        = list(string)
}

variable "bootstrap_name" {
  description = "Name to use for the bootstrap node group."
  type        = string
}

variable "bootstrap_vm_size" {
  description = "VM size to use for the bootstrap node group."
  type        = string
}

variable "logging_storage_account_id" {
  description = "Optional ID of a storage account to add cluster logs to.."
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

variable "windows_support" {
  description = "If the Kubernetes cluster should support Windows nodes."
  type        = bool
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
}

variable "cluster_tags" {
  description = "Tags to apply to the cluster."
  type        = map(string)
}

variable "timeouts" {
  description = "Timeout configuration."
  type = object({
    cluster_read   = number
    cluster_modify = number
  })
}

variable "maintenance_window_offset" {
  description = "Maintenance window offset to utc."
  type        = number
}

variable "maintenance_window_allowed_days" {
  description = "List of allowed days covering the maintenance window."
  type        = list(string)
}

variable "maintenance_window_allowed_hours" {
  description = "List of allowed hours covering the maintenance window."
  type        = list(number)
}

variable "maintenance_window_not_allowed" {
  description = "Array of not allowed blocks including start and end times in rfc3339 format. A not allowed block takes priority if it overlaps an allowed blocks in a maintenance window."
  type = list(object({
    start = string
    end   = string
  }))
}

# tflint-ignore: terraform_unused_declarations
variable "experimental" {
  description = "Provide experimental feature flag configuration."
  type        = any
}
