locals {
  coredns_custom = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name : "coredns-custom"
      namespace : var.namespace
      labels = var.labels
    }
    data = {
      "onpremzones.server" = local.forward_zone_config
    }
  }

  forward_zone_config = <<-EOT
    %{for zone, ip in var.forward_zones~}
    ${zone}:53 {
      forward . ${ip}
    }
    %{endfor}
  EOT

  resource_files   = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_objects = { coredns_custom = local.coredns_custom }
}
