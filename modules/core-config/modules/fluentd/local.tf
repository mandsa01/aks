locals {
  chart_version = "2.7.1"

  chart_values = merge({
    nameOverride = "fluentd"

    podLabels = merge(var.labels, {
      aadpodidbinding = module.identity.name
    })

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
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

    dashboards = {
      enabled = true
    }

    replicaCount = var.zones

    podDisruptionBudget = {
      enabled        = true
      maxUnavailable = 1
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

    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [{
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"     = "fluentd"
              "app.kubernetes.io/instance" = "fluentd"
            }
          }
          topologyKey = "topology.kubernetes.io/zone"
        }]
      }
    }

    resources = {
      requests = {
        cpu    = "500m"
        memory = "512Mi"
      }

      limits = {
        cpu    = "1000m"
        memory = "512Mi"
      }
    }

    persistence = {
      enabled      = true
      storageClass = "azure-disk-premium-ssd-delete"
      accessMode   = "ReadWriteOnce"
      size         = "64Gi"
    }

    env = [for k, v in local.additional_env : { name = k, value = v }]

    debug = var.debug

    config = {
      forward = local.forward_config
      filter  = local.filter_config
      route   = local.route_config
      output  = local.output_config
    }
  }, local.image_override)

  image_override = length(var.image_repository) > 0 && length(var.image_tag) > 0 ? {
    image = {
      repository = var.image_repository
      tag        = var.image_tag
    }
  } : {}

  additional_env = merge({
    "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR" = "0.9"
    "SUBSCRIPTION_ID"                     = var.subscription_id
    "LOCATION"                            = var.location
    "CLUSTER_NAME"                        = var.cluster_name
  }, var.additional_env)

  default_route = <<-EOT
    <route **>
      @label @DEFAULT
    </route>
  EOT

  default_output = <<-EOT
    <label @DEFAULT>
      <match **>
        @type null
      </match>
    </label>
  EOT

  forward_config = <<-EOT
    <source>
      @type forward
      @id input
      port 24224
      bind 0.0.0.0
    </source>
  EOT

  filter_config = <<-EOT
    <filter **>
      @type record_modifier
      <record>
        cloud azure
        subscriptionId "#{ENV['SUBSCRIPTION_ID']}"
        location "#{ENV['LOCATION']}"
        cluster "#{ENV['CLUSTER_NAME']}"
        node $${record.dig("kubernetes","host")}
        namespace $${record.dig("kubernetes","namespace") || record.dig("kubernetes","namespace_name") }
        pod $${record.dig("kubernetes","pod_name")}
        container $${record.dig("kubernetes","container_name")}
        containerHash $${record.dig("kubernetes","container_hash")}
        containerImage $${record.dig("kubernetes","container_image")}
        app $${record.dig("kubernetes","labels","app.kubernetes.io/name") || record.dig("kubernetes","pod_name")}
        instance $${record.dig("kubernetes","labels","app.kubernetes.io/instance") || record.dig("kubernetes","pod_name")}
        componentTemp $${ c = record.dig("kubernetes","labels","app.kubernetes.io/component"); c.nil? ? c : record["component"] = c; }
        partOfTemp $${ p = record.dig("kubernetes","labels","app.kubernetes.io/part-of"); p.nil? ? p : record["partOf"] = p; }
        versionTemp $${ v = record.dig("kubernetes","labels","app.kubernetes.io/version"); v.nil? ? v : record["version"] = v; }
        labels $${record.dig("kubernetes","labels")}
        annotations $${record.dig("kubernetes","annotations")}
        kubernetes
        stream
      </record>
      remove_keys stream, versionTemp, partOfTemp, componentTemp, kubernetes
    </filter>
    %{if length(var.filters) > 0~}
    ${var.filters}
    %{endif~}
  EOT

  route_config = <<-EOT
    <match **>
      @type route
      <route **>
        copy
        @label @PROMETHEUS
      </route>
      ${indent(2, length(var.routes) > 0 ? var.routes : local.default_route)}
    </match>
  EOT

  output_config = length(var.outputs) > 0 ? var.outputs : local.default_output

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
