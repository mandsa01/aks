locals {
  chart_version = "35.4.2"

  chart_values = {
    global = {
      rbac = {
        create     = true
        pspEnabled = false
      }
    }

    commonLabels = merge(var.labels, {
      "lnrs.io/monitoring-platform" = "true"
    })

    prometheusOperator = {
      enabled = true

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
          cpu    = "200m"
          memory = "512Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      createCustomResource = false
      manageCrds           = false

      prometheusConfigReloader = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "16Mi"
          }

          limits = {
            cpu    = "050m"
            memory = "16Mi"
          }
        }
      }

      admissionWebhooks = {
        patch = {
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
        }

        certManager = {
          enabled = true
        }
      }
    }

    prometheus = {
      prometheusSpec = {
        retention = "28d"

        remoteWrite = var.prometheus_remote_write

        podMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }

        serviceMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }

        ruleSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "true"
            "lnrs.io/prometheus-rule"     = "true"
          }
        }

        logLevel  = "info"
        logFormat = "json"

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

        podAntiAffinity            = "hard"
        podAntiAffinityTopologyKey = "topology.kubernetes.io/zone"

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "azure-disk-premium-ssd-delete"

              accessModes : [
                "ReadWriteOnce"
              ]

              resources = {
                requests = {
                  storage = "512Gi"
                }
              }
            }
          }
        }

        resources = {
          requests = {
            cpu    = "500m"
            memory = "4096Mi"
          }

          limits = {
            cpu    = "2000m"
            memory = "4096Mi"
          }
        }
      }

      ingress = {
        enabled          = true
        annotations      = var.ingress_annotations
        ingressClassName = var.ingress_class_name
        pathType         = "Prefix"
        hosts            = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          hosts = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }
    }

    alertmanager = {
      alertmanagerSpec = {
        priorityClassName = ""

        retention = "120h"

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

        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "azure-disk-premium-ssd-delete"

              accessModes : [
                "ReadWriteOnce"
              ]

              resources = {
                requests = {
                  storage = "16Gi"
                }
              }
            }
          }
        }

        resources = {
          requests = {
            cpu    = "10m"
            memory = "64Mi"
          }

          limits = {
            cpu    = "1000m"
            memory = "64Mi"
          }
        }
      }

      config = {
        global = {
          smtp_require_tls = false
          smtp_smarthost   = var.alertmanager_smtp_host
          smtp_from        = var.alertmanager_smtp_from
        }

        receivers = local.alertmanager_receivers

        route = {
          group_by = [
            "namespace",
            "severity"
          ]
          group_wait      = "30s"
          group_interval  = "5m"
          repeat_interval = "12h"
          receiver        = "null"

          routes = local.alertmanager_routes
        }
      }

      ingress = {
        enabled          = true
        annotations      = var.ingress_annotations
        ingressClassName = var.ingress_class_name
        pathType         = "Prefix"
        hosts            = ["alertmanager-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          hosts = ["alertmanager-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }
    }

    grafana = {
      enabled = true

      rbac = {
        create     = true
        pspEnabled = false
      }

      podLabels = {
        aadpodidbinding = module.identity_grafana.name
      }

      admin = {
        existingSecret = kubernetes_secret.grafana_auth.metadata[0].name
        userKey        = "admin-user"
        passwordKey    = "admin-password"
      }

      "grafana.ini" = {
        "auth.anonymous" = {
          enabled  = true
          org_role = "Viewer"
        }

        users = {
          viewers_can_edit = true
        }

        azure = {
          managed_identity_enabled = true
        }
      }

      plugins = distinct(concat([
        "grafana-piechart-panel"
      ], var.grafana_additional_plugins))

      additionalDataSources = concat([local.grafana_azure_monitor_data_source], var.grafana_additional_data_sources)

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

      ingress = {
        enabled          = true
        annotations      = var.ingress_annotations
        ingressClassName = var.ingress_class_name
        pathType         = "Prefix"
        path             = "/"
        hosts            = ["grafana-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          hosts = ["grafana-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "128Mi"
        }
      }

      sidecar = {
        dashboards = {
          searchNamespace = "ALL"
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }

          limits = {
            cpu    = "1000m"
            memory = "128Mi"
          }
        }
      }
    }

    kubeScheduler = {
      enabled = false
    }

    kubeControllerManager = {
      enabled = false
    }

    kubeEtcd = {
      enabled = false
    }

    kubeProxy = {
      enabled = true

      service = {
        selector = {
          component = "kube-proxy"
        }
      }
    }

    defaultRules = {
      create = false
    }

    ## Deploy servicemonitor
    kubeStateMetrics = {
      enabled = true
    }

    kube-state-metrics = {
      podSecurityPolicy = {
        enabled = false
      }

      prometheus = {
        monitor = {
          enabled = true
          additionalLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
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
          cpu    = "50m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "128Mi"
        }
      }
    }

    nodeExporter = {
      enabled = true
    }

    prometheus-node-exporter = {
      rbac = {
        create     = true
        pspEnabled = false
      }

      prometheus = {
        monitor = {
          enabled = true
          additionalLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }
      }

      priorityClassName = "system-node-critical"

      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }

      tolerations = [{
        operator = "Exists"
      }]

      updateStrategy = {
        type = "RollingUpdate"

        rollingUpdate = {
          maxUnavailable = "25%"
        }
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "64Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "64Mi"
        }
      }
    }
  }

  alertmanager_base_receivers = [{
    name              = "null"
    email_configs     = []
    opsgenie_configs  = []
    pagerduty_configs = []
    pushover_configs  = []
    slack_configs     = []
    sns_configs       = []
    victorops_configs = []
    webhook_configs   = []
    wechat_configs    = []
    # telegram_configs  = []
  }]
  alertmanager_default_receivers = length(var.alertmanager_receivers) > 0 ? [] : [{
    name              = "alerts"
    email_configs     = []
    opsgenie_configs  = []
    pagerduty_configs = []
    pushover_configs  = []
    slack_configs     = []
    sns_configs       = []
    victorops_configs = []
    webhook_configs   = []
    wechat_configs    = []
    # telegram_configs  = []
  }]
  alertmanager_receivers = concat(local.alertmanager_base_receivers, local.alertmanager_default_receivers, [for receiver in var.alertmanager_receivers : {
    name              = receiver.name
    email_configs     = lookup(receiver, "email_configs", [])
    opsgenie_configs  = lookup(receiver, "opsgenie_configs", [])
    pagerduty_configs = lookup(receiver, "pagerduty_configs", [])
    pushover_configs  = lookup(receiver, "pushover_configs", [])
    slack_configs     = lookup(receiver, "slack_configs", [])
    sns_configs       = lookup(receiver, "sns_configs", [])
    victorops_configs = lookup(receiver, "victorops_configs", [])
    webhook_configs   = lookup(receiver, "webhook_configs", [])
    wechat_configs    = lookup(receiver, "wechat_configs", [])
    # telegram_configs  = lookup(receiver, "telegram_configs", [])
  }])

  alertmanager_base_routes = [{
    receiver            = "null"
    group_by            = []
    continue            = false
    matchers            = ["alertname=Watchdog"]
    group_wait          = "30s"
    group_interval      = "5m"
    repeat_interval     = "12h"
    mute_time_intervals = []
  }]
  alertmanager_default_routes = length(var.alertmanager_routes) > 0 ? [] : [{
    receiver            = "alerts"
    group_by            = []
    continue            = false
    matchers            = ["severity=~warning|critical"]
    group_wait          = "30s"
    group_interval      = "5m"
    repeat_interval     = "12h"
    mute_time_intervals = []
  }]
  alertmanager_routes = concat(local.alertmanager_base_routes, local.alertmanager_default_routes, [for route in var.alertmanager_routes : {
    receiver            = route.receiver
    group_by            = lookup(route, "group_by", [])
    continue            = lookup(route, "continue", false)
    matchers            = route.matchers
    group_wait          = lookup(route, "group_wait", "30s")
    group_interval      = lookup(route, "group_interval", "5m")
    repeat_interval     = lookup(route, "repeat_interval", "12h")
    mute_time_intervals = lookup(route, "mute_time_intervals", [])
  }])

  loki_data_source = {
    name   = "Loki"
    type   = "loki"
    url    = "http://loki-gateway.logging.svc.cluster.local"
    access = "proxy"
    orgId  = "1"
  }

  grafana_azure_monitor_data_source = {
    name      = "Azure Monitor"
    type      = "grafana-azure-monitor-datasource"
    orgId     = "1"
    isDefault = false
    jsonData = {
      subscriptionId = var.subscription_id
    }
  }

  resource_group_id                             = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  oms_log_analytics_workspace_resource_group_id = var.oms_agent && var.oms_log_analytics_workspace_id != "" ? regex("([[:ascii:]]*)(/providers/)", var.oms_log_analytics_workspace_id)[0] : ""

  crd_files           = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files      = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
  dashboard_templates = { for x in fileset(path.module, "resources/configmap-dashboard-*.yaml.tpl") : basename(x) => { path = "${path.module}/${x}", vars = { resource_id = var.control_plane_log_analytics_workspace_id, subscription_id = var.subscription_id } } }
}
