locals {

  ad_member_domains = {
    public       = "onmicrosoft.com"
    usgovernment = "onmicrosoft.us"
  }

  upn_regex = "(?i)@[a-z0-9-]+\\.${local.ad_member_domains[var.azure_env]}"

  user_object_ids = distinct([for username, object_id in merge(var.azuread_clusterrole_map.cluster_admin_users, var.azuread_clusterrole_map.cluster_view_users, var.azuread_clusterrole_map.standard_view_users) : object_id])

  cluster_admin_users = [for username, object_id in var.azuread_clusterrole_map.cluster_admin_users : length(regexall(local.upn_regex, username)) > 0 ? username : object_id]

  cluster_view_users = [for username, object_id in var.azuread_clusterrole_map.cluster_view_users : length(regexall(local.upn_regex, username)) > 0 ? username : object_id]

  standard_view_users = [for username, object_id in var.azuread_clusterrole_map.standard_view_users : length(regexall(local.upn_regex, username)) > 0 ? username : object_id]

  standard_view_groups = values(var.azuread_clusterrole_map.standard_view_groups)
}
