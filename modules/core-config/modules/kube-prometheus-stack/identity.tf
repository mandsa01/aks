module "identity_grafana" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  name      = "${var.cluster_name}-grafana"
  namespace = var.namespace
  labels    = var.labels

  ## By default Grafana is granted access to
  ##   - Reader access to the cluster Resource Group
  ##   - Log Analytics Reader access to the cluster log analytics workspace (cluster metrics and diagnostic logs)
  ## If oms_log_analytics_workspace_id is set as a module variable
  ##   - Reader access to its Resource Group
  ##   - Log Analytics Reader access to the Workspace
  roles = concat([
    { id = "Reader", scope = local.resource_group_id },
    { id = "Log Analytics Reader", scope = var.control_plane_log_analytics_workspace_id }
    ], var.oms_agent ? [
    { id = "Log Analytics Reader", scope = var.oms_log_analytics_workspace_id }
    ] : [], var.oms_log_analytics_workspace_different_resource_group ? [
    { id = "Reader", scope = local.oms_log_analytics_workspace_resource_group_id }
  ] : [])

  tags = var.tags
}
