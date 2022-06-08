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

resource "helm_release" "default" {
  name      = "cert-manager"
  namespace = var.namespace

  repository = "https://charts.jetstack.io/"
  chart      = "cert-manager"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = 600

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    kubectl_manifest.crds
  ]
}

resource "kubectl_manifest" "issuers" {
  for_each = local.issuers

  yaml_body = yamlencode(each.value)

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.default
  ]
}
