module "identity_private" {
  source = "../../../identity"
  count  = local.enable_private ? 1 : 0

  location            = var.location
  resource_group_name = var.resource_group_name

  name      = "${var.cluster_name}-external-dns-private"
  namespace = var.namespace
  labels    = var.labels

  roles = concat([{
    id    = "Reader"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.private_dns_zone_resource_group_name}"
    }], [for zone in var.private_domain_filters : {
    id    = "Private DNS Zone Contributor"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.private_dns_zone_resource_group_name}/providers/Microsoft.Network/privateDnsZones/${zone}"
  }])

  tags = var.tags
}

module "identity_public" {
  source = "../../../identity"
  count  = local.enable_public ? 1 : 0

  location            = var.location
  resource_group_name = var.resource_group_name

  name      = "${var.cluster_name}-external-dns-public"
  namespace = var.namespace
  labels    = var.labels

  roles = concat([{
    id    = "Reader"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.public_dns_zone_resource_group_name}"
    }], [for zone in var.public_domain_filters : {
    id    = "DNS Zone Contributor"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.public_dns_zone_resource_group_name}/providers/Microsoft.Network/dnszones/${zone}"
  }])

  tags = var.tags
}
