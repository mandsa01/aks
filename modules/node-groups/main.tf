resource "azurerm_proximity_placement_group" "default" {
  for_each = toset(local.placement_group_names)

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

module "system_node_groups" {
  source   = "./modules/node-group"
  for_each = local.system_node_groups

  name                         = each.value.name
  cluster_id                   = var.cluster_id
  cluster_version_full         = var.cluster_version_full
  network_plugin               = var.network_plugin
  subnet_id                    = var.subnet_id
  availability_zones           = each.value.availability_zones
  system                       = true
  min_capacity                 = each.value.min_capacity
  max_capacity                 = each.value.max_capacity
  node_os                      = each.value.node_os
  node_type                    = each.value.node_type
  node_type_version            = each.value.node_type_version
  node_size                    = each.value.node_size
  proximity_placement_group_id = each.value.proximity_placement_group_id
  labels                       = merge(var.labels, each.value.labels)
  taints                       = each.value.taints
  tags                         = merge(var.tags, each.value.tags)
}

module "bootstrap_node_group_hack" {
  source = "./modules/bootstrap-node-group-hack"

  subscription_id     = var.subscription_id
  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name
  subnet_id           = var.subnet_id
  bootstrap_name      = var.bootstrap_name
  bootstrap_vm_size   = var.bootstrap_vm_size

  depends_on = [
    module.system_node_groups
  ]
}

module "user_node_groups" {
  source   = "./modules/node-group"
  for_each = local.user_node_groups

  name                         = each.value.name
  cluster_id                   = var.cluster_id
  cluster_version_full         = var.cluster_version_full
  network_plugin               = var.network_plugin
  subnet_id                    = var.subnet_id
  availability_zones           = each.value.availability_zones
  system                       = false
  min_capacity                 = each.value.min_capacity
  max_capacity                 = each.value.max_capacity
  node_os                      = each.value.node_os
  node_type                    = each.value.node_type
  node_type_version            = each.value.node_type_version
  node_size                    = each.value.node_size
  proximity_placement_group_id = each.value.proximity_placement_group_id
  labels                       = merge(var.labels, each.value.labels)
  taints                       = each.value.taints
  tags                         = merge(var.tags, each.value.tags)

  depends_on = [
    module.bootstrap_node_group_hack
  ]
}
