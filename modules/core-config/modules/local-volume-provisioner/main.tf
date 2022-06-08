resource "helm_release" "default" {
  name      = "local-volume-provisioner"
  namespace = var.namespace

  repository = "https://flachesis.github.io/sig-storage-local-static-provisioner/"
  chart      = "provisioner"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = 600

  values = [
    yamlencode(local.chart_values)
  ]
}
