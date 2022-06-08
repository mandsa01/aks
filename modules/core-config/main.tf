resource "kubernetes_namespace" "default" {
  for_each = toset(local.namespaces)

  metadata {
    name = each.key

    labels = merge(var.labels, {
      name = each.key
    })
  }
}

module "storage" {
  source = "./modules/storage"

  labels = var.labels
}

resource "kubectl_manifest" "kube_prometheus_stack_crds" {
  for_each = { for x in fileset(path.module, "modules/kube-prometheus-stack/crds/*.yaml") : basename(x) => "${path.module}/${x}" }

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true
}

module "aad_pod_identity" {
  source = "./modules/aad-pod-identity"

  subscription_id          = var.subscription_id
  resource_group_name      = var.resource_group_name
  node_resource_group_name = var.node_resource_group_name
  network_plugin           = var.network_plugin
  kubelet_identity_id      = var.kubelet_identity_id
  namespace                = "kube-system"
  labels                   = var.labels

  experimental = var.experimental

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds
  ]
}

module "cert_manager" {
  source = "./modules/cert-manager"

  azure_environment         = local.azure_environment
  tenant_id                 = var.tenant_id
  subscription_id           = var.subscription_id
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_resource_group_lookup = var.dns_resource_group_lookup
  cluster_name              = var.cluster_name
  namespace                 = kubernetes_namespace.default["cert-manager"].metadata[0].name
  labels                    = var.labels
  acme_dns_zones            = distinct(concat([local.ingress_internal_core.domain], local.cert_manager.acme_dns_zones))
  additional_issuers        = local.cert_manager.additional_issuers
  default_issuer_kind       = local.cert_manager.default_issuer_kind
  default_issuer_name       = local.cert_manager.default_issuer_name
  tags                      = var.tags

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds,
    module.aad_pod_identity
  ]
}

module "coredns" {
  source = "./modules/coredns"

  namespace     = "kube-system"
  labels        = var.labels
  forward_zones = local.coredns.forward_zones

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds
  ]
}

module "external_dns" {
  source = "./modules/external-dns"

  azure_environment         = local.azure_environment
  tenant_id                 = var.tenant_id
  subscription_id           = var.subscription_id
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_resource_group_lookup = var.dns_resource_group_lookup
  cluster_name              = var.cluster_name
  namespace                 = kubernetes_namespace.default["dns"].metadata[0].name
  labels                    = var.labels
  additional_sources        = local.external_dns.additional_sources
  private_domain_filters    = local.ingress_internal_core.public_dns ? local.external_dns.private_domain_filters : distinct(concat([local.ingress_internal_core.domain], local.external_dns.private_domain_filters))
  public_domain_filters     = local.ingress_internal_core.public_dns ? distinct(concat([local.ingress_internal_core.domain], local.external_dns.public_domain_filters)) : local.external_dns.public_domain_filters
  tags                      = var.tags

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds,
    module.aad_pod_identity
  ]
}

module "fluent_bit" {
  source = "./modules/fluent-bit"

  namespace = kubernetes_namespace.default["logging"].metadata[0].name
  labels    = var.labels

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds,
    module.storage,
    module.fluentd
  ]
}

module "fluentd" {
  source = "./modules/fluentd"

  subscription_id     = var.subscription_id
  location            = var.location
  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name
  namespace           = kubernetes_namespace.default["logging"].metadata[0].name
  labels              = var.labels
  zones               = local.az_count
  image_repository    = local.fluentd.image_repository
  image_tag           = local.fluentd.image_tag
  additional_env      = local.fluentd.additional_env
  debug               = local.fluentd.debug
  filters             = local.fluentd.filters
  routes              = local.fluentd.routes
  outputs             = local.fluentd.outputs
  tags                = var.tags

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds,
    module.storage,
    module.aad_pod_identity
  ]
}

module "ingress_internal_core" {
  source = "./modules/ingress-internal-core"

  namespace               = kubernetes_namespace.default["ingress-core-internal"].metadata[0].name
  labels                  = var.labels
  lb_subnet_name          = var.subnet_name
  lb_source_cidrs         = local.ingress_internal_core.lb_source_cidrs
  domain                  = local.ingress_internal_core.domain
  certificate_issuer_kind = local.cert_manager.default_issuer_kind
  certificate_issuer_name = local.cert_manager.default_issuer_name

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds,
    module.cert_manager
  ]
}

module "kube_prometheus_stack" {
  source = "./modules/kube-prometheus-stack"

  subscription_id                                      = var.subscription_id
  location                                             = var.location
  resource_group_name                                  = var.resource_group_name
  cluster_name                                         = var.cluster_name
  namespace                                            = kubernetes_namespace.default["monitoring"].metadata[0].name
  labels                                               = var.labels
  zones                                                = local.az_count
  prometheus_remote_write                              = local.prometheus.remote_write
  alertmanager_smtp_host                               = local.alertmanager.smtp_host
  alertmanager_smtp_from                               = local.alertmanager.smtp_from
  alertmanager_receivers                               = local.alertmanager.receivers
  alertmanager_routes                                  = local.alertmanager.routes
  grafana_admin_password                               = local.grafana.admin_password
  grafana_additional_plugins                           = local.grafana.additional_plugins
  grafana_additional_data_sources                      = local.grafana.additional_data_sources
  ingress_class_name                                   = module.ingress_internal_core.ingress_class_name
  ingress_domain                                       = local.ingress_internal_core.domain
  ingress_subdomain_suffix                             = local.ingress_internal_core.subdomain_suffix
  ingress_annotations                                  = local.ingress_internal_core.annotations
  control_plane_log_analytics_workspace_id             = var.control_plane_log_analytics_workspace_id
  oms_agent                                            = var.oms_agent
  oms_log_analytics_workspace_id                       = var.oms_log_analytics_workspace_id
  oms_log_analytics_workspace_different_resource_group = var.oms_log_analytics_workspace_different_resource_group
  skip_crds                                            = true
  tags                                                 = var.tags

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds,
    module.storage,
    module.aad_pod_identity,
    module.cert_manager,
    module.ingress_internal_core
  ]
}

module "local_volume_provisioner" {
  source = "./modules/local-volume-provisioner"

  namespace = "kube-system"
  labels    = var.labels

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_crds
  ]
}
