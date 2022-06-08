resource "kubectl_manifest" "crds" {
  for_each = local.crd_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "resource_files" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.crds
  ]
}

resource "kubernetes_secret" "private_config" {
  count = local.enable_private ? 1 : 0

  metadata {
    name      = "external-dns-private-config"
    namespace = var.namespace
    labels    = var.labels
  }

  type = "Opaque"

  data = {
    config = <<-EOF
      {
        "cloud": "${var.azure_environment}",
        "tenantId": "${var.tenant_id}",
        "subscriptionId": "${var.subscription_id}",
        "resourceGroup": "${local.private_dns_zone_resource_group_name}",
        "useManagedIdentityExtension": true
      }
    EOF
  }
}

resource "helm_release" "private" {
  count = local.enable_private ? 1 : 0

  name      = "external-dns-private"
  namespace = var.namespace

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = 600

  values = [
    yamlencode(local.chart_values_private)
  ]

  depends_on = [
    kubectl_manifest.crds
  ]
}

resource "kubernetes_secret" "public_config" {
  count = local.enable_public ? 1 : 0

  metadata {
    name      = "external-dns-public-config"
    namespace = var.namespace
    labels    = var.labels
  }

  type = "Opaque"

  data = {
    config = <<-EOF
      {
        "cloud": "${var.azure_environment}",
        "tenantId": "${var.tenant_id}",
        "subscriptionId": "${var.subscription_id}",
        "resourceGroup": "${local.public_dns_zone_resource_group_name}",
        "useManagedIdentityExtension": true
      }
    EOF
  }
}

resource "helm_release" "public" {
  count = local.enable_public ? 1 : 0

  name      = "external-dns-public"
  namespace = var.namespace

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = 600

  values = [
    yamlencode(local.chart_values_public)
  ]

  depends_on = [
    kubectl_manifest.crds
  ]
}
