locals {
  name = "core-internal"

  chart_version = "4.1.1"

  chart_values = {
    commonLabels = var.labels

    controller = {
      service = {
        annotations = {
          "service.beta.kubernetes.io/azure-load-balancer-internal"        = "true"
          "service.beta.kubernetes.io/azure-load-balancer-internal-subnet" = var.lb_subnet_name
        }

        type                  = "LoadBalancer"
        externalTrafficPolicy = "Local"

        loadBalancerSourceRanges = var.lb_source_cidrs

        enableHttps = true
        enableHttp  = true
      }

      metrics = {
        enabled = true

        serviceMonitor = {
          enabled = true

          additionalLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }
      }

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

      affinity = {
        podAntiAffinity = {
          preferredDuringSchedulingIgnoredDuringExecution = [
            {
              podAffinityTerm = {
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = "ingress-nginx"
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "controller"
                  }
                }

                topologyKey = "kubernetes.io/hostname"
              }

              weight = 100
            }
          ]
        }
      }

      priorityClassName = ""

      resources = {
        requests = {
          cpu    = "50m"
          memory = "256Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }

      autoscaling = {
        enabled                           = true
        minReplicas                       = 3
        maxReplicas                       = 6
        targetCPUUtilizationPercentage    = 80
        targetMemoryUtilizationPercentage = 80
      }

      updateStrategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxSurge       = "100%"
          maxUnavailable = 0
        }
      }

      minAvailable = "33%"

      ingressClassResource = {
        enabled         = true
        name            = local.name
        default         = false
        controllerValue = "k8s.io/nginx-${local.name}"
        parameters      = {}
      }

      ingressClass = ""

      config = {
        "server-name-hash-bucket-size" = "256"
        "server-tokens"                = "false"
        "use-proxy-protocol"           = "false"
        "use-forwarded-headers"        = "true"
      }

      proxySetHeaders = {
        "Referrer-Policy" = "strict-origin-when-cross-origin"
      }

      extraArgs = {
        "enable-ssl-chain-completion" = "false"
        "default-ssl-certificate"     = "${var.namespace}/internal-ingress-wildcard-cert"
      }

      allowSnippetAnnotations = "false"

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
      }
    }

    defaultBackend = {
      enabled      = true
      replicaCount = 3
      minAvailable = 1

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

      priorityClassName = ""

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
  }

  certificate = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "internal-ingress-wildcard"
      namespace = var.namespace
      labels    = var.labels
    }

    spec = {
      dnsNames = [
        var.domain,
        "*.${var.domain}"
      ]

      issuerRef = {
        group = "cert-manager.io"
        kind  = var.certificate_issuer_kind
        name  = var.certificate_issuer_name
      }

      secretName = "internal-ingress-wildcard-cert"
    }
  }

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
