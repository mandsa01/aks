locals {
  azure_environments = {
    "public"       = "AzurePublicCloud"
    "usgovernment" = "AzureUSGovernmentCloud"
  }

  azure_environment = local.azure_environments[var.azure_env]

  az_count = length(var.availability_zones)

  namespaces = [
    "cert-manager",
    "dns",
    "logging",
    "ingress-core-internal",
    "monitoring"
  ]

  alertmanager = merge({
    smtp_host = ""
    smtp_from = ""
    receivers = []
    routes    = []
  }, lookup(var.core_services_config, "alertmanager", {}))

  cert_manager = merge({
    acme_dns_zones      = []
    additional_issuers  = {}
    default_issuer_kind = "ClusterIssuer"
    default_issuer_name = "letsencrypt-staging"
  }, lookup(var.core_services_config, "cert_manager", {}))

  coredns = merge({
    forward_zones = {}
  }, lookup(var.core_services_config, "coredns", {}))

  external_dns = merge({
    additional_sources     = []
    private_domain_filters = []
    public_domain_filters  = []
  }, lookup(var.core_services_config, "external_dns", {}))

  fluentd = merge({
    image_repository = ""
    image_tag        = ""
    additional_env   = {}
    debug            = true
    filters          = ""
    routes           = ""
    outputs          = ""
  }, lookup(var.core_services_config, "fluentd", {}))

  grafana = merge({
    admin_password          = "changeme"
    additional_data_sources = []
    additional_plugins      = []
  }, lookup(var.core_services_config, "grafana", {}))

  ingress_internal_core_tmp = merge({
    domain           = ""
    subdomain_suffix = var.cluster_name
    lb_source_cidrs  = ["10.0.0.0/8", "100.65.0.0/16"]
    public_dns       = false
  }, lookup(var.core_services_config, "ingress_internal_core", {}))

  ingress_internal_core = merge(local.ingress_internal_core_tmp, {
    annotations = {
      "lnrs.io/zone-type" = local.ingress_internal_core_tmp.public_dns ? "public" : "private"
    }
  })

  prometheus = merge({
    remote_write = []
  }, lookup(var.core_services_config, "prometheus", {}))
}
