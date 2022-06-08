resource "kubectl_manifest" "resource_files" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true
}

resource "helm_release" "default" {
  name      = "fluentd"
  namespace = var.namespace

  repository = "https://stevehipwell.github.io/helm-charts/"
  chart      = "fluentd-aggregator"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = 600

  values = [
    yamlencode(local.chart_values)
  ]
}
