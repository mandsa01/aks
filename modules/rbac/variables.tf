variable "azure_env" {
  description = "Azure cloud environment type."
  type        = string
}

variable "cluster_id" {
  description = "ID of the Azure Kubernetes managed cluster."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users  = map(string)
      cluster_view_users   = map(string)
      standard_view_users  = map(string)
      standard_view_groups = map(string)
    }
  )
}
