module "identity" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  name      = "${var.cluster_name}-fluentd"
  namespace = var.namespace
  labels    = var.labels

  roles = [{
    id    = "Reader"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${var.cluster_name}"
  }]

  tags = var.tags
}
