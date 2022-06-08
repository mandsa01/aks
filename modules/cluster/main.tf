resource "azurerm_user_assigned_identity" "default" {
  name                = "${var.cluster_name}-control-plane"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "network_contributor_network" {
  principal_id         = azurerm_user_assigned_identity.default.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.subnet_id
}

resource "azurerm_role_assignment" "network_contributor_route_table" {
  principal_id         = azurerm_user_assigned_identity.default.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.route_table_id
}

resource "azurerm_kubernetes_cluster" "default" {
  name                      = var.cluster_name
  kubernetes_version        = var.cluster_version_full
  automatic_channel_upgrade = "node-image"
  sku_tier                  = var.sku_tier_paid ? "Paid" : "Free"

  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.default.id]
  }

  public_network_access_enabled   = var.cluster_endpoint_public_access
  api_server_authorized_ip_ranges = length(var.cluster_endpoint_access_cidrs) == 0 ? ["0.0.0.0/32"] : var.cluster_endpoint_access_cidrs

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = "calico"
    outbound_type      = "loadBalancer"
    service_cidr       = "172.20.0.0/16"
    dns_service_ip     = "172.20.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    pod_cidr           = var.network_plugin == "kubenet" ? var.podnet_cidr_block : null
  }

  dns_prefix = var.cluster_name

  local_account_disabled            = true
  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  azure_policy_enabled = false

  auto_scaler_profile {
    balance_similar_node_groups   = true
    expander                      = "random"
    skip_nodes_with_system_pods   = false
    skip_nodes_with_local_storage = false
  }

  dynamic "oms_agent" {
    for_each = var.oms_agent ? ["default"] : []
    content {
      log_analytics_workspace_id = var.oms_log_analytics_workspace_id
    }
  }

  dynamic "windows_profile" {
    for_each = var.windows_support ? ["default"] : []
    content {
      admin_username = random_password.windows_admin_username[0].result
      admin_password = random_password.windows_admin_password[0].result
    }
  }

  maintenance_window {
    dynamic "allowed" {
      for_each = local.maintenance_window.allowed
      content {
        day   = allowed.value.day
        hours = allowed.value.hours
      }
    }
    dynamic "not_allowed" {
      for_each = local.maintenance_window.not_allowed
      content {
        end   = not_allowed.value.end
        start = not_allowed.value.start
      }
    }
  }

  node_resource_group = "mc_${var.cluster_name}"

  default_node_pool {
    name = var.bootstrap_name

    type           = "VirtualMachineScaleSets"
    vnet_subnet_id = var.subnet_id
    zones          = [1, 2, 3]

    orchestrator_version = var.cluster_version_full

    node_count                   = 1
    enable_auto_scaling          = false
    only_critical_addons_enabled = true

    vm_size                = var.bootstrap_vm_size
    os_disk_type           = "Managed"
    enable_host_encryption = true
    enable_node_public_ip  = false

    tags = var.tags
  }

  tags = merge(var.cluster_tags, var.tags)

  timeouts {
    create = format("%vm", var.timeouts.cluster_modify / 60)
    read   = format("%vm", var.timeouts.cluster_read / 60)
    update = format("%vm", var.timeouts.cluster_modify / 60)
    delete = format("%vm", var.timeouts.cluster_modify / 60)
  }

  lifecycle {
    ignore_changes = [default_node_pool]
  }

  depends_on = [
    azurerm_role_assignment.network_contributor_network,
    azurerm_role_assignment.network_contributor_route_table
  ]
}
