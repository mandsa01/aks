locals {
  default_storage_classes = {
    azure-disk-standard-ssd-retain = {
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "StandardSSD_LRS"
      }
      reclaim_policy         = "Retain"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }

    azure-disk-premium-ssd-retain = {
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "Premium_LRS"
      }
      reclaim_policy         = "Retain"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }

    azure-disk-standard-ssd-delete = {
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "StandardSSD_LRS"
      }
      reclaim_policy         = "Delete"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }

    azure-disk-premium-ssd-delete = {
      parameters = {
        cachingmode        = "ReadOnly"
        kind               = "Managed"
        storageaccounttype = "Premium_LRS"
      }
      reclaim_policy         = "Delete"
      mount_options          = ["debug"]
      volume_binding_mode    = "WaitForFirstConsumer"
      allow_volume_expansion = true
    }
  }
}
