locals {
  chart_version = "4.1.10"

  chart_values = {
    rbac = {
      enabled              = true
      allowAccessToSecrets = false
    }

    forceNamespaced = true

    installCRDs = false

    mic = {
      priorityClassName = "system-cluster-critical"

      nodeSelector = {
        "kubernetes.io/os" = "linux"
        "lnrs.io/tier"     = "system"
      }

      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          key      = "system"
          operator = "Exists"
        }
      ]

      podLabels = var.labels

      podDisruptionBudget = {
        minAvailable = 1
      }

      resources = {
        requests = {
          cpu    = "20m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "128Mi"
        }
      }
    }

    nmi = {
      priorityClassName = "system-node-critical"

      allowNetworkPluginKubenet = (var.network_plugin == "kubenet" ? true : false)

      tolerations = [{
        operator = "Exists"
      }]

      podLabels = var.labels

      resources = {
        requests = {
          cpu    = "20m"
          memory = "64Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "64Mi"
        }
      }
    }
  }

  finalizer_wait = lookup(var.experimental, "aad_pod_identity_finalizer_wait", "120s")

  crd_files = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
}
