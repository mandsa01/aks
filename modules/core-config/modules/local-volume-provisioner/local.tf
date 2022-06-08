locals {
  chart_version = "2.5.0"

  chart_values = {
    common = {
      rbac = {
        create     = true
        pspEnabled = false
      }

      serviceAccount = {
        create = true
      }

      useNodeNameOnly = true
    }

    serviceMonitor = {
      enabled = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    daemonset = {
      podLabels = var.labels

      nodeSelector = {
        "lnrs.io/local-storage" = "true"
      }

      tolerations = [
        {
          operator = "Exists"
        }
      ]

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "64Mi"
        }
      }
    }

    classes = [
      {
        blockCleanerCommand = [
          "/scripts/shred.sh",
          "2",
        ]
        fsType      = "ext4"
        hostDir     = "/dev"
        mountDir    = "/mnt/nvme"
        name        = "local-nvme-delete"
        namePattern = "nvme*"
        volumeMode  = "Filesystem"
      },
      {
        blockCleanerCommand = [
          "/scripts/shred.sh",
          "2",
        ]
        fsType      = "ext4"
        hostDir     = "/dev"
        mountDir    = "/mnt/ssd"
        name        = "local-ssd-delete"
        namePattern = "sdb1*"
        volumeMode  = "Filesystem"
      }
    ]
  }
}
