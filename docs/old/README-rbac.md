# Role Based Access Control (RBAC)

## Kubernetes RBAC

### Cluster Roles

To assign Azure AD users or groups to Kubernetes cluster roles, use the `azuread_clusterrole_map` as follows.

```yaml
  azuread_clusterrole_map = {
    cluster_admin_users  = {
      "murtaghj@b2b.regn.net" = "d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1"
    }
    cluster_view_users = {
      "IOB AKS-1 View MID"    = "ca55d5e2-99f6-4047-baef-333313edcf98"
    }
    standard_view_users  = {
      "longm@b2b.regn.net"    = "d64e3f6b-6b16-4235-b4ce-67baa24a593d"
      "patelp@b2b.regn.net"   = "60b29c0c-00bb-48b3-9b9a-cfc3213c5d7d"
    }
    standard_view_groups = {
      "IOB AKS Viewers"       = "3494a2b5-d6e5-49f2-9cf7-542004cbe44d"
    }
  }
```

* Map keys   - AD UPN (*e.g. murtaghj@b2b.regn.net*)
* Map Values - Azure AD user and group UIDs, see [Object Id Lookup](#object-id-lookup) to find them

---

#### Object Id Lookup

Azure AD user and group Object Ids can be found within the Azure Portal or API in the **`RBAHosting tenant`**.

Azure Portal - select *Azure Active Directory* then either *Users* or *Groups*, select the resource then copy the *Object Id* field.

API - example using the `az` cli:

```bash
$ az ad user show --id murtaghj_b2b.regn.net#EXT#@RBAHosting.onmicrosoft.com --query objectId -o tsv
d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1
$ az ad group show --group "IOB AKS Viewers" --query objectId -o tsv
3494a2b5-d6e5-49f2-9cf7-542004cbe44d
```

---

#### Role Assignment

Role assignment for all but basic view permissions is only supported for Azure AD users (not groups), for the following reasons.

* To provide more transparency for cluster operators or InfoSec teams reviewing the Terraform code or Azure role assignments
* To ensure role assignment is managed in tandem with cluster lifecycle (*e.g. roles will be unassigned on cluster deletion*)

The latter is due to Azure AD Groups not being managed by Terraform due to the high level of privileges required in the Azure AD tenant. 

This necessitates groups be managed independently, however there isn't a robust mechanism to manage this currently.

---

#### Role Mapping

The `azuread_clusterrole_map` roles map to the following Kubernetes clusterroles.

* `cluster_admin_users` - bound to the built-in _**cluster-admin**_ clusterrole, providing full access to the cluster
* `cluster_view_users` - bound to the _**lnrs:cluster-view**_ role with full read access to the cluster, including sensitive data (*e.g. secrets*)
* `standard_view_users` - bound to the _**lnrs:view**_ role, inherited from the built-in _**view**_ clusterrole with custom added permissions
* `standard_view_groups` - bound to the _**lnrs:view**_ role, inherited from the built-in _**view**_ clusterrole with custom added permissions

Additional roles may be added if there is a valid use case across all clusters.

<br>

## Azure RBAC

### AKS Cluster User Role

The [AKS Cluster User Role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-cluster-user-role) is required to [download the cluster kubeconfig](https://docs.microsoft.com/en-us/azure/aks/control-kubeconfig-access) for Azure AD integrated clusters.

This is assigned to all AAD users or groups configured within `azuread_clusterrole_map`, directly on the AKS cluster resource.

### AKS Cluster Admin Role

The [AKS Cluster Admin Role](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-cluster-admin-role) is required to retrive the cluster-admin credentials.

This role in avalable to subscription Contributors and must only be used in break-glass scenarios where Azure AD integration is broken. 

<br>

## Module Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|cluster_id|AKS cluster resource Id|string|n/a|yes|
|azuread_clusterrole_map|Map of Kubernetes roles to AAD user or group Ids|<pre>object({<br>    cluster_admin_users  = map(string)<br>    cluster_view_users   = map(string)<br>    standard_view_users  = map(string)<br>    standard_view_groups = map(string)<br>})</pre>|null|no|
