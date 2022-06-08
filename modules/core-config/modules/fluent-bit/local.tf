locals {
  chart_version = "0.20.1"

  chart_values = {
    serviceMonitor = {
      enabled = true
      selector = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    dashboards = {
      enabled = true
    }

    updateStrategy = {
      type = "RollingUpdate"

      rollingUpdate = {
        maxUnavailable = "25%"
      }
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

    nodeSelector = {
      "kubernetes.io/os" = "linux"
    }

    tolerations = [{
      operator = "Exists"
    }]

    podLabels = var.labels

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
    }

    priorityClassName = "system-node-critical"

    daemonSetVolumes = [
      {
        name = "logs"
        hostPath = {
          path = "/var/log"
        }
      },
      {
        name = "containers"
        hostPath = {
          path = "/var/lib/docker/containers"
        }
      },
      {
        name = "machine-id"
        hostPath = {
          path = "/etc/machine-id"
          type = "File"
        }
      }
    ]

    daemonSetVolumeMounts = [
      {
        name      = "logs"
        mountPath = "/var/log"
        readOnly  = true
      },
      {
        name      = "containers"
        mountPath = "/var/lib/docker/containers"
        readOnly  = true
      },
      {
        name      = "machine-id"
        mountPath = "/etc/machine-id"
        readOnly  = true
      }
    ]

    extraVolumes = [
      {
        name = "state"
        hostPath = {
          path = "/var/fluent-bit/state"
        }
      }
    ]

    extraVolumeMounts = [
      {
        name      = "state"
        mountPath = "/var/fluent-bit/state"
      }
    ]

    config = {
      service = local.service_config
      inputs  = local.input_config
      filters = local.filter_config
      outputs = local.output_config
    }
  }

  service_config = <<-EOT
    [SERVICE]
      daemon                    false
      log_level                 info
      storage.path              /var/fluent-bit/state/flb-storage/
      storage.sync              normal
      storage.checksum          false
      storage.max_chunks_up     512
      storage.backlog.mem_limit 16M
      storage.metrics           true
      http_server               true
      http_listen               0.0.0.0
      http_port                 2020
      flush                     5
      parsers_file              parsers.conf
      parsers_file              custom_parsers.conf
  EOT

  input_config = <<-EOT
    [INPUT]
      name              tail
      tag               kube.*
      path              /var/log/containers/*.log
      read_from_head    true
      refresh_interval  10
      rotate_wait       30
      multiline.parser  cri, docker
      skip_long_lines   true
      skip_empty_lines  true
      buffer_chunk_size 32k
      buffer_max_size   256k
      db                /var/fluent-bit/state/flb-storage/tail-containers.db
      db.sync           normal
      db.locking        true
      db.journal_mode   wal
      mem_buf_limit     16MB
      storage.type      filesystem

    [INPUT]
      name              systemd
      tag               node.*
      systemd_filter    _SYSTEMD_UNIT=docker.service
      systemd_filter    _SYSTEMD_UNIT=containerd.service
      systemd_filter    _SYSTEMD_UNIT=kubelet.service
      strip_underscores true
      db                /var/fluent-bit/state/flb-storage/systemd.db
      db_sync           normal
      storage.type      filesystem
  EOT

  filter_config = <<-EOT
    [FILTER]
      name                kubernetes
      match               kube.*
      merge_log           true
      merge_log_trim      true
      keep_log            false
      k8s-logging.parser  true
      k8s-logging.exclude true
  EOT

  output_config = <<-EOT
    [OUTPUT]
      name                     forward
      match                    *
      host                     fluentd.logging.svc.cluster.local
      port                     24224
      storage.total_limit_size 16GB
  EOT

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
