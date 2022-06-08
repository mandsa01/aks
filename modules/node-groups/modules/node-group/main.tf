resource "azurerm_kubernetes_cluster_node_pool" "default" {
  name = var.name

  kubernetes_cluster_id = var.cluster_id
  orchestrator_version  = var.cluster_version_full

  vnet_subnet_id = var.subnet_id
  zones          = var.availability_zones

  mode = var.system ? "System" : "User"

  priority            = "Regular"
  enable_auto_scaling = local.enable_auto_scaling
  node_count          = local.enable_auto_scaling ? null : var.max_capacity
  min_count           = local.enable_auto_scaling ? var.min_capacity : null
  max_count           = local.enable_auto_scaling ? var.max_capacity : null

  upgrade_settings {
    max_surge = 1
  }

  os_type = local.os_types[var.node_os]
  os_sku  = local.os_skus[var.node_os]

  vm_size                = local.vm_sizes["${local.node_arch}-${var.node_type}-${var.node_type_version}"][var.node_size]
  os_disk_size_gb        = 128
  os_disk_type           = "Managed"
  enable_host_encryption = true
  enable_node_public_ip  = false

  proximity_placement_group_id = var.proximity_placement_group_id

  max_pods    = local.max_pods[var.network_plugin]
  node_labels = merge(local.vm_labels["${local.node_arch}-${var.node_type}"], { "lnrs.io/lifecycle" = "ondemand", "lnrs.io/size" = var.node_size }, var.labels)
  node_taints = [for taint in concat(local.vm_taints["${local.node_arch}-${var.node_type}"], var.taints) : "${taint.key}=${taint.value}:${local.taint_effects[taint.effect]}"]

  tags = var.tags
}
