locals {
  chart_version = "1.9.0"

  chart_values = {
    serviceMonitor = {
      enabled = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    priorityClassName = ""

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

    resources = {
      requests = {
        cpu    = "10m"
        memory = "128Mi"
      }

      limits = {
        cpu    = "1000m"
        memory = "128Mi"
      }
    }

    logFormat = "json"

    sources = concat(["service", "ingress"], var.additional_sources)

    policy = "sync"

    txtOwnerId = var.cluster_name

    env = [{
      name  = "AZURE_ENVIRONMENT"
      value = var.azure_environment
    }]

    extraVolumeMounts = [{
      name      = "azure-config-file"
      mountPath = "/etc/kubernetes"
      readOnly  = true
    }]
  }

  chart_values_private = merge(local.chart_values, {
    nameOverride = "external-dns-private"

    podLabels = merge(var.labels, {
      aadpodidbinding = local.enable_private ? module.identity_private[0].name : ""
    })

    extraVolumes = [{
      name = "azure-config-file"
      secret = {
        secretName = local.enable_private ? kubernetes_secret.private_config[0].metadata[0].name : ""
        items = [{
          key  = "config"
          path = "azure.json"
        }]
      }
    }]

    provider = "azure-private-dns"

    domainFilters = var.private_domain_filters

    extraArgs = concat([
      "--azure-config-file=/etc/kubernetes/azure.json",
      "--annotation-filter=lnrs.io/zone-type in (private, public-private)"
    ], contains(var.additional_sources, "crd") ? local.crd_args : [])
  })

  chart_values_public = merge(local.chart_values, {
    nameOverride = "external-dns-public"

    podLabels = merge(var.labels, {
      aadpodidbinding = local.enable_public ? module.identity_public[0].name : ""
    })

    extraVolumes = [{
      name = "azure-config-file"
      secret = {
        secretName = local.enable_public ? kubernetes_secret.public_config[0].metadata[0].name : ""
        items = [{
          key  = "config"
          path = "azure.json"
        }]
      }
    }]

    provider = "azure"

    domainFilters = var.public_domain_filters

    extraArgs = concat([
      "--azure-config-file=/etc/kubernetes/azure.json",
      "--annotation-filter=lnrs.io/zone-type in (public, public-private)"
    ], contains(var.additional_sources, "crd") ? local.crd_args : [])
  })

  crd_args = [
    "--crd-source-apiversion=externaldns.k8s.io/v1alpha1",
    "--crd-source-kind=DNSEndpoint"
  ]

  private_dns_zone_resource_group_name = one(distinct([for zone in var.private_domain_filters : var.dns_resource_group_lookup[zone]]))
  public_dns_zone_resource_group_name  = one(distinct([for zone in var.public_domain_filters : var.dns_resource_group_lookup[zone]]))

  enable_private = length(var.private_domain_filters) > 0 && local.private_dns_zone_resource_group_name != null
  enable_public  = length(var.public_domain_filters) > 0 && local.public_dns_zone_resource_group_name != null

  crd_files      = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
