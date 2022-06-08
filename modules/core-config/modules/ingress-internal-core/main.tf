resource "kubectl_manifest" "resource_files" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "certificate" {
  yaml_body = yamlencode(local.certificate)

  server_side_apply = true
  wait              = true
}

resource "helm_release" "default" {
  name      = local.name
  namespace = var.namespace

  repository = "https://kubernetes.github.io/ingress-nginx/"
  chart      = "ingress-nginx"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = 1800

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    kubectl_manifest.certificate
  ]
}

resource "time_sleep" "lb_detach" {
  destroy_duration = "30s"

  depends_on = [
    helm_release.default
  ]
}
