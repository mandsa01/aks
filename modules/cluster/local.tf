data "azurerm_client_config" "current" {
}

locals {
  log_categories = {
    all = ["kube-apiserver", "kube-audit", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]

    recommended = ["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]

    limited = ["kube-apiserver", "kube-controller-manager", "cloud-controller-manager", "guard"]
  }

  logging_config = merge({
    workspace = {
      name                       = "control-plane-workspace"
      log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id
      storage_account_id         = null
      logs                       = local.log_categories[local.workspace_log_categories]
      metrics                    = []
      retention_enabled          = false
      retention_days             = 0
    }
    }, length(var.logging_storage_account_id) > 0 ? {
    storage_account = {
      name                       = "control-plane-storage-account"
      log_analytics_workspace_id = null
      storage_account_id         = var.logging_storage_account_id
      logs                       = local.log_categories[local.storage_log_categories]
      metrics                    = []
      retention_enabled          = true
      retention_days             = 7
    }
  } : {})

  maintenance_window_location_offsets = {
    westeurope = 0
    uksouth    = 0
    eastus     = 5
    eastus2    = 5
    centralus  = 6
    westus     = 8

  }

  maintenance_window_offset = var.maintenance_window_offset != null ? var.maintenance_window_offset : lookup(local.maintenance_window_location_offsets, var.location, 0)

  maintenance_window_allowed_days = length(var.maintenance_window_allowed_days) == 0 ? ["Tuesday", "Wednesday", "Thursday"] : var.maintenance_window_allowed_days

  maintenance_window_allowed_hours = length(var.maintenance_window_allowed_hours) == 0 ? [10, 11, 12, 13, 14, 15] : var.maintenance_window_allowed_hours

  maintenance_window_not_allowed = length(var.maintenance_window_not_allowed) == 0 ? [] : var.maintenance_window_not_allowed

  maintenance_window = {
    allowed = [for d in local.maintenance_window_allowed_days : {
      day   = d
      hours = [for h in local.maintenance_window_allowed_hours : h + local.maintenance_window_offset]
    }]
    not_allowed = [for x in local.maintenance_window_not_allowed : {
      start = timeadd(x.start, format("%vh", local.maintenance_window_offset))
      end   = timeadd(x.end, format("%vh", local.maintenance_window_offset))
    }]
  }

  workspace_log_categories = lookup(var.experimental, "workspace_log_categories", "recommended")
  storage_log_categories   = lookup(var.experimental, "storage_log_categories", "recommended")
}
