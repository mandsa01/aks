resource "azurerm_role_assignment" "cluster_user" {
  for_each = toset(local.user_object_ids)

  principal_id = each.value

  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  scope                = var.cluster_id
}

resource "kubernetes_cluster_role" "cluster_view" {
  metadata {
    name = "lnrs:cluster-view"

    labels = var.labels
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role" "view" {
  metadata {
    name = "lnrs:view"

    labels = var.labels

    annotations = {
      "rbac.authorization.kubernetes.io/autoupdate" = "true"
    }
  }

  aggregation_rule {
    cluster_role_selectors {
      match_labels = {
        "rbac.authorization.k8s.io/aggregate-to-view" = "true"
      }
    }

    cluster_role_selectors {
      match_labels = {
        "lnrs.io/aggregate-to-view" = "true"
      }
    }
  }
}

resource "kubernetes_cluster_role" "node_view" {
  metadata {
    name = "lnrs:node-view"

    labels = merge(var.labels, { "lnrs.io/aggregate-to-view" = "true" })
  }

  rule {
    api_groups = [""]
    resources  = ["node"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_admin" {
  count = length(local.cluster_admin_users) > 0 ? 1 : 0
  metadata {
    name = "lnrs:cluster-admin"

    labels = var.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  dynamic "subject" {
    for_each = toset(local.cluster_admin_users)
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "User"
      name      = subject.value
    }
  }
}

resource "kubernetes_cluster_role_binding" "cluster_view" {
  count = length(local.cluster_view_users) > 0 ? 1 : 0

  metadata {
    name = "lnrs:cluster-view"

    labels = var.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_view.metadata[0].name
  }

  dynamic "subject" {
    for_each = toset(local.cluster_view_users)
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "User"
      name      = subject.value
    }
  }
}

resource "kubernetes_cluster_role_binding" "standard_view" {
  count = (length(local.standard_view_users) + length(local.standard_view_groups)) > 0 ? 1 : 0

  metadata {
    name = "lnrs:standard-view"

    labels = var.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.view.metadata[0].name
  }

  dynamic "subject" {
    for_each = toset(local.standard_view_users)
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "User"
      name      = subject.value
    }
  }

  dynamic "subject" {
    for_each = toset(local.standard_view_groups)
    content {
      api_group = "rbac.authorization.k8s.io"
      kind      = "Group"
      name      = subject.value
    }
  }
}
