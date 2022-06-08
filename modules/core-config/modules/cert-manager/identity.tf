module "identity" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  name      = "${var.cluster_name}-cert-manager"
  namespace = var.namespace
  labels    = var.labels

  roles = concat([for zone in var.acme_dns_zones : {
    id    = "DNS Zone Contributor"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.dns_resource_group_lookup[zone]}/providers/Microsoft.Network/dnszones/${zone}"
  }])

  tags = var.tags
}
