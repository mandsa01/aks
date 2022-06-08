resource "kubectl_manifest" "resource_files" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "resource_objects" {
  for_each = local.resource_objects

  yaml_body = yamlencode(each.value)

  server_side_apply = true
  wait              = true
}
