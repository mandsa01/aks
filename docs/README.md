# AKS Documentation

- [AKS Documentation](#aks-documentation)
  - [Architecture](#architecture)
    - [Prerequisites](#prerequisites)
    - [Virtual Network Requirements](#virtual-network-requirements)
    - [CNI Options](#cni-options)
    - [Node Memory Allocation](#node-memory-allocation)
    - [Platform Resource Settings](#platform-resource-settings)
  - [Module User Guide](#module-user-guide)
    - [Control Plane Uptime SLA](#control-plane-uptime-sla)
    - [Cluster Upgrades](#cluster-upgrades)
    - [Kubernetes RBAC](#kubernetes-rbac)
    - [DNS, TLS Certificates & Ingress](#dns-tls-certificates--ingress)
    - [ACR Access](#acr-access)
    - [Grafana Access to Azure Resources](#grafana-access-to-azure-resources)
    - [External Persistent Disks](#external-persistent-disks)
    - [Local Volumes](#local-volumes)
    - [Multiple Clusters per Subnet](#multiple-clusters-per-subnet)
    - [Proximity Placement Groups](#proximity-placement-groups)
  - [Service User Guide](#service-user-guide)
    - [Azure AD Pod Identity](#azure-ad-pod-identity)
    - [Ingress](#ingress)
    - [External DNS](#external-dns)
    - [Coredns](#coredns)
    - [TLS Certificates](#tls-certificates)
    - [Network Policy](#network-policy)
    - [Metrics & Alerts](#metrics--alerts)
    - [Azure Monitor Container Insights](#azure-monitor-container-insights)

<br>

## Architecture

The following diagram shows the standard network topology and resource group layout for an AKS cluster.

![AKS Network Architecture](/docs/images/aks_network_architecture.png)

---

### Prerequisites 

The following prerequisites must be met in advance of deploying an AKS cluster.

* `Subscription` - activation of the [encryption at host](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli#prerequisites) feature on subscriptions which host AKS clusters
* `Resource Groups` - to host VNet, DNS and AKS resources
* `VNet` - a set of dedicated subnets & associated route table for each AKS cluster
* `DNS`  - at least one public zone to host ingress / service records

A [default subscription DNS public zone](https://reedelsevier.sharepoint.com/sites/OG-CoP-Cloud/SitePages/DNS-Zone-Naming-Conventions.aspx) (and Resource Group) may have been created as part of the subscription deployment process. If additional public zones are required they **must** be deployed to the same resource group for `external-dns` to access them.

The [encryption at host](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli#prerequisites) feature *may* be applied to newer subscriptions, if not a user with subscription Contributor permissions must execute the following commands:

```bash
### Check EncryptionAtHost feature is Registered
$ az account set --subscription <subscription_name>
$ az feature show --name EncryptionAtHost --namespace Microsoft.Compute
Name                                RegistrationState
----------------------------------  -------------------
Microsoft.Compute/EncryptionAtHost  NotRegistered

### If not, register via the following commands
$ az feature register --namespace Microsoft.Compute --name EncryptionAtHost
$ az feature show --name EncryptionAtHost --namespace Microsoft.Compute      (may take up to 30 minutes to register)
$ az provider register -n Microsoft.Compute
```

Node pools are split into 3 classifications; the `system node pools` hosts cluster services and is completely managed by the module; `user node pools` host user workloads, multiple pools can be deployed and then targeted or isolated using node labels and taints respectively; `ingress node pools` are used to route external traffic into the cluster and are the only pool to be deployed into a public subnet. NSG rules prohibit routing of internet traffic directly to private subnets.

The module `resource_group_name` variable specifies the resource group to deploy the `AKS service` into. This could share the VNet resource group  or be deployed into a dedicated pool. Consideration should be given if multiple VNets and clusters are to be deployed to a subscription and hence Azure RBAC isolation between teams. 

> in addition, Azure creates a fully managed `MC_<cluster-name>` resource group to host AKS managed resources. No user-managed resources should be created in this resource group.

---

### Virtual Network Requirements

A VNet could be shared with non-AKS resources, however there **must** be a pair of dedicated public and private subnets and a unique route table for each AKS cluster (use the [terraform-azure-virtual-network](https://github.com/Azure-Terraform/terraform-azurerm-virtual-network) module `aks_subnets` variable to meet this requirement, see [examples](/examples) for usage). While it is technically possible to host multiple AKS cluster node pools in a subnet, see [guidance](#multiple-clusters-per-subnet) on why this is not recommended.

Subnet configuration, in particular sizing, will largely depend on the network plugin (CNI) used, see [CNI Options](#cni-options) below.

If the [dns_servers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network#dns_servers) attribute is set for the virtual network, the Azure DNS server "168.63.129.16" must be included in the list of values.

---

### CNI Options

The following table lists properties and considerations when choosing the CNI plugin.

| **Description**                              | **kubenet**      | **Azure CNI** |
| :------------------------------------------- | :--------------- | :------------ |
| The default network plugin.                  | `true`           | `false`       |
| Subnet sized based on number of...           | `hosts`          | `pods`        |
| Default pods supported per node (`max_pods`).| `110`            | `30`          |
| Nodes (and pods) supported on a /24 network. | `251` (`27,610`) | `8` (`240`)   |
| Support for Windows node pools.              | `false`          | `true`        |
| Support for multiple clusters in a subnet.   | `false`          | `true`        |

Also see the [official comparison table](https://docs.microsoft.com/en-us/azure/aks/concepts-network#compare-network-models) for more information.

Subnets must be sized to accommodate node pool upgrade and scaling events.

It is recommended to use the `kubenet` plugin unless Windows node pools are required or the application has extremely low latency requirements (where sub-millisecond latency is a significant factor).

---

### Node Memory Allocation

It's important to understand memory available to user workloads (versus system reserved) and how this affects node sizing.

With the introduction of System Node Pools, most core platform services are hosted in a dedicated node pool, so these requirements don't have to be considered for user node pools. However, [AKS reserves resources](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#resource-reservations) for the `kubelet` service, while platform `daemonset` reservations also need to be considered. 

AKS reserves 750MB on each node, plus a variable rate depending on the node size (`25% of first 4GB, 20% of next 4GB, 10% of next 8GB and 6% up to 128GB*`). In addition, platform `daemonsets` use or reserve ~650MB of RAM, plus there will be a relatively small amount required by the kernel.

| **Node Size**     | **AKS Reserved** | **Daemonsets** | **Allocatable** |
| :-----------------| :----------------| :--------------| :---------------|
| medium (4 GB)     | 1.75 GB          | 650 MB         | 1.6 GB          |
| large (8 GB)      | 2.55 GB          | 650 MB         | 4.8 GB          |
| xlarge (16 GB)    | 3.35 GB          | 650 MB         | 12 GB           |
| 2xlarge (32 GB)   | 4.15 GB          | 650 MB         | 27.2 GB         |

Expanding to node pool memory usage, a 6-node large pool will reserve 19.2 GB versus 12 GB for a 3-node xlarge pool, both providing the same 48 GB to total RAM. **Almost a full node's memory is wasted on the smaller node type in this scenario**. Using larger nodes provides better memory density, however this should be balanced against user workload requirements and anticipated scaling events.

The platform team are constantly reviewing `daemonset` reservations to reduce the memory footprint. In future, the platform will scale reservations based on the total cluster size and how services scale in response to load. It is likely platform resources will increase in the short-term due to new requirements, i.e. to add security services, so ensure this is regularly reviewed during resource planning.

---

### Platform Resource Settings

The system node pools hosts services for a variety of functions (i.e. metrics, logs, certificates, cloud integration). Some have a static resource profile, others will vary considerably under load on the cluster or number of resources (i.e. nodes, pods). In addition, the topology of Azure subscriptions makes it likely there will be a high number of small clusters, while on the other hand the platform must also support large HPCC clusters. These conditions together make it very difficult to set resource requests and limits to meet all use cases and achieve a balance of cost efficiency and scaling.

In general, resources that scale due to load or resource density will have lower requests but higher limits to try and account for more scenarios. In the event of node saturation, the system node pools support limited horizontal scaling.

It is the collective responsibility of all teams to monitor system service metrics and report back to the engineering team when either requests or limits are exceeded on an extended basis. This will very much be an ongoing effort to refine and tune these settings, ideally to the point where the platform can scale them automatically for different conditions.

> commands such as `kubectl top`, `kubectl describe node` and Grafana dashboards can help to track resource usage

<br>
<br>

## Module User Guide

How to interact with the Terraform module to deploy an AKS cluster.

### Control Plane Uptime SLA

The `sku_tier` variable is required to set the control plane [Uptime SLA](https://docs.microsoft.com/en-us/azure/aks/uptime-sla), set to either `Free` or `Paid`.

Setting to `Paid` increases control plane scalability, performance and availability (99.95%), as well as a financially backed guarantee for a fee of $0.10 per hour ($72 pcm). It is recommended to select this option for production clusters or those that require additional availability guarantees.

---

### Cluster Upgrades

A cluster upgrade is initiated by one of the following changes:

* A user updates the `cluster_version` module input to the next minor/major AKS version
* The module internally updates the supported patch revision for a supported AKS version

When changes are applied, the following workflow commences:

* The AKS control plane and default node pool are updated to the new version
* Once complete, all other node pools are updated **simultaneously** by rolling through nodes sequentially

Given the above, here are some best practices and considerations:

* Consult the [Upgrade Guide](/UPGRADE.md) for necessary manual steps or considerations - if not the operation **will fail**
* Ensure the Terraform pipeline has a sufficient timeout to allow the operation to complete
  * It is recommended to provide 10 minutes per node (or 2 hours as a minimum)
* Scale down node pools if possible, in particular batch workloads that may be stopped and resumed
* For `Azure CNI`, ensure at least (*no of node pools*)*30 free IP addresses in the subnet
  * Azure CNI pre-allocates 30 IPs for each node (see [CNI Options](#cni-options) above)
* Ensure workloads are spread across pools, if necessary use [Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) or other availability options
* Don't perform upgrades when the cluster is processing high-intensity workloads
* Fewer, larger nodes will take less time to upgrade than many smaller nodes

---

### Kubernetes RBAC

[Cluster authentication](https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli#access-cluster-with-azure-ad) is managed via Azure AD (SSO) in the `RBAHosting` tenant.

Azure AD users or services accounts (managed identities) will need some level of administrative access to the cluster, either for general maintenance and visibility or to hand off to automation platforms to deploy user services. A basic set of Kubernetes administrative and viewer roles are provided via the `azuread_clusterrole_map` variable.

```yaml
  azuread_clusterrole_map = {
    cluster_admin_users  = {
      "bloggsj@risk.regn.net"    = "d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1"
    }
    cluster_view_users = {
      "Accurint CDB MID"         = "ca55d5e2-99f6-4047-baef-333313edcf98"
    }
    standard_view_users  = {}
    standard_view_groups = {
      "Accurint AKS View Access" = "3494a2b5-d6e5-49f2-9cf7-542004cbe44d"
    }
  }
```

In `AzureUSGovernmentCloud` environments the map key **must** be the User Principal name. For `AzurePublicCloud` the key may be the UPN or descriptive field, however it is highly recommended to use the UPN as this is unique and easily referenced.

After handover it's possible for teams to create additional roles and bindings for Azure AD users, however this **must not** include the `cluster-admin` role - this high privileged role must be fully managed by this variable for transparency and auditing by InfoSec and SRE teams. See the [RBAC](/modules/core-config/modules/rbac/README.md) documentation for full implementation details.

For service accounts, a managed identity can be configured for non-interactive `kubectl` access, see [kubelogin](https://docs.microsoft.com/en-us/azure/aks/managed-aad#non-interactive-sign-in-with-kubelogin) for details.

---

### DNS, TLS Certificates & Ingress

Configuration for these areas is closely aligned and configured via inputs in the `core_services_config` variable.

For example, the module exposes ingress endpoints for core services such as Prometheus, Grafana and AlertManager UIs. The endpoints must be secured via TLS and DNS records must be published to Azure DNS for clients to resolve.


```yaml
  core_services_config = {
    cert_manager = {
      dns_zones  = {
        "us-accurint-prod.azure.lnrsg.io" = "us-accurint-prod-dns-rg"
      }
    }

    external_dns= {
      private_resource_group_name = "us-accurint-prod-dns-rg"
      private_zones = [ "us-accurint-prod.azure.lnrsg.io" ]
    }

    ingress_internal_core = {
      domain    = "us-accurint-prod.azure.lnrsg.io"
    }
  }
```

The `cert-manager` block specifies the **public zone** Let's Encrypt will use to validate the domain and its resource group. 

The `external-dns` block specifies domain(s) that user services can expose DNS records through and their resource group - all zones managed by `external-dns` **must** be in a single resource group. 

The `ingress_internal_core` block specifies the domain to expose ingress resources to, consuming DNS/TLS services above. 

It's very likely the same primary domain will be configured for all services, perhaps with `external-dns` managing some additional domains. The resource group is a required input so the module can assign appropriate Azure role bindings. It is expected that in most cases all DNS domains will be hosted in a single resource group.

While `external-dns` supports both public and private zones, in split-horizon setups only the private zone should be configured, otherwise both zones will be updated with service records. The only scenario for configuring both public and private zones of the same name is to migrate public records to private records. Once this is done, the public zone should be removed and records manually deleted in the public zone.

See the [Ingress](/modules/core-config/modules/ingress_internal_core/README.md) documentation for implementation details.

---

### ACR Access

To support pulling images from a private Azure Container Registry (ACR), add an Azure role assignment for the VMSS node (`kubelet`) identity to the appropriate ACR.

```yaml
resource "azurerm_role_assignment" "accurint_acr" {
  scope                = azurerm_container_registry.accurintacr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity.object_id
}
```

The code above requires the ACR and AKS resources be deployed in the same project/subscription and the Terraform user has access to modify them. In many cases, an ACR could be shared by many clusters and deployed in a central subscription, hence the role assignment would need to happen there (this is the reason ACR access is not supported by the module directly).

---

### Grafana Access to Azure Resources

To support the in-cluster Grafana service to query Azure resources such as metrics or logs from a Log Analytics workspace, add an Azure role assignment for the Grafana managed identity to the appropriate resource group and workspace.

```yaml
resource "azurerm_role_assignment" "grafana_accurint_log_analytics_rg_reader" {
  scope                = azurerm_resource_group.accurint_log_analytics_rg.id
  role_definition_name = "Reader"
  principal_id         = module.aks.grafana_identity
}

resource "azurerm_role_assignment" "grafana_log_analytics_workspace_reader" {
  scope                = azurerm_log_analytics_workspace.accurint.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = module.aks.grafana_identity
}
```

> Grafana needs `Reader` access to the Resource Group for service discovery

For convenience, the module automatically configures the following:

* Adds a Grafana `Azure Monitor` data source to query Azure resources via a managed identity
* Adds role assignments for the managed identity to all resources within the AKS cluster resource group
* Adds role assignments to the workspace added via the `log_analytics_workspace_id` variable (if set)

AKS cluster resource group roles provides access to Azure cluster metrics and control plane diagnostics logs stored in a Log Analytics workspace within it.

---

### External Persistent Disks

In many cases it is useful to re-use a storage volume, whether moving between clusters or re-assigning to a cluster that has been destroyed and recreated. The storage classes supplied in the module create disks in the cluster managed resource group (named `MC_<cluster-name>`) by default. An implication is if a cluster is destroyed, all disks (and indeed all resources) in the managed resource group are deleted, even if the StorageClass `ReclaimPolicy` is set to `Retain`. 

To avoid this behaviour disks must be created in an external resource group, either via Kubernetes through a StorageClass, or via the Azure API then imported. The former method has the advantage that everything is managed within Kubernetes and a default set of tags is applied to Azure storage. The latter supports custom tags, plus doesn't require any changes to Kubernetes manifests between source and target systems.

This guide assumes an external resource group `aks-shared-storage-rg` has already been deployed.

**Option 1 - Dynamic StorageClass Provisioning**

* Create a new `StorageClass` configured to write to the external resource group
* Configure Azure Role assignments for any cluster that is to access the resource group
* On the source cluster, deploy a `PersistentVolumeClaim` using the StorageClass
* On the target cluster, import the storage via a `PersistentVolume` definition

Configure and deploy the the StorageClass - **note the `resourceGroup` parameter**:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-disk-remote-ssd-retain
mountOptions:
- debug
parameters:
  cachingmode: ReadOnly
  kind: Managed
  storageaccounttype: Premium_LRS
  resourceGroup: aks-shared-storage-rg
provisioner: kubernetes.io/azure-disk
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

Use the control plane managed identity (AKS module `principal_id` output) in the Azure Role assignment for the external resource group. **Repeat for every cluster that needs access to it**.

```yaml
resource "azurerm_role_assignment" "shared_storage_cluster_1" {
  scope                = azurerm_resource_group.shared_storage.id
  role_definition_name = "Disk Restore Operator"
  principal_id         = module.aks.principal_id
}
```

Create the Kubernetes resource with a PersistentVolumeClaim, then take a note of the Azure name and resource Id. 

> this information can also be found in the Azure console via `disk Properties`

```bash
$ kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                   AGE
pvc-external   Bound    pvc-4a479495-3ea6-4f41-97d7-e462d0ae1334   2Gi        RWO            azure-disk-remote-ssd-retain   19h

$ kubectl describe pv pvc-4a479495-3ea6-4f41-97d7-e462d0ae1334 | grep Disk
    Type:         AzureDisk (an Azure Data Disk mount on the host and bind mount to the pod)
    DiskName:     pvc-4a479495-3ea6-4f41-97d7-e462d0ae1334
    DiskURI:      /subscriptions/bbe8caed-4d35-41e2-9ffd-4a771708c341/resourceGroups/iob-dev-westeurope-akstest-rg-shared-storage/providers/Microsoft.Compute/disks/pvc-4a479495-3ea6-4f41-97d7-e462d0ae1334
```

The disk can now be deleted on the cluster (or the cluster deleted).

On the remote cluster, the same Kubernetes manifest can be applied with one change; a `PersistentVolume` resource must be specified using the `DiskName` & `DiskURI` properties above. The PersistentVolume will also link to the PersistentVolumeClaim (which doesn't need to be changed) via a `claimRef`.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvc-4a479495-3ea6-4f41-97d7-e462d0ae1334
spec:
  storageClassName: "azure-disk-remote-ssd-retain"
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  claimRef:
    namespace: default
    name: pvc-external
  azureDisk:
    diskName: pvc-4a479495-3ea6-4f41-97d7-e462d0ae1334
    diskURI: /subscriptions/bbe8caed-4d35-41e2-9ffd-4a771708c341/resourceGroups/iob-dev-westeurope-akstest-rg-shared-storage/providers/Microsoft.Compute/disks/pvc-4a479495-3ea6-4f41-97d7-e462d0ae1334
    kind: Managed
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-external
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: azure-disk-remote-ssd-retain
```

Any `storageClassName` can be used on the remote cluster, however it is useful to replicate settings from the source so it retains any other capabilities, i.e. volume expansion or cloning.

**Option 2 - Manual Disk Provisioning**

* Create a new storage volume via Terraform or the Azure API
* Configure Azure Role assignments for any cluster that is to access the resource group
* Create a `PersistentVolume` definition within the Kubernetes manifest, specifying the `DiskName` & `DiskURI` properties

As an example, use the [azurerm_managed_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) resource to create a disk in the external resource group. Repeat the steps above to add the Azure Role assignment to this group. Use the same Kubernetes manifest above specifying the `DiskName` & `DiskURI` properties to target the disk on any cluster, which has the advantage the same manifest can be used throughout the workflow without modification.

> for this reason this is the recommended approach

---

### Local Volumes

For node types in the [node type/size matrix](/modules/nodes/matrix.md) with either local SSD or NVME storage, these disks will automatically be converted to [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and be available for pods on the node to claim via a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

There are a few important considerations when using these volumes.

* It's possible the disk may already contain data from other Azure customers, this is not scrubbed before mounting
* The [encryption at host](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli#prerequisites) feature will only protect RSG data on SSD volumes, not NVME volumes
  * NVME volume data **must** be encrypted by another means - this is the users responsibility
* If a `PersistentVolumeClaim` is deleted the disk will be scrubbed shortly after by the `daemonset`
  * This could take several hours for large disks and incur a lot of IO and processing cycles
* If a node is deleted the `PersistentVolume` is retained on the cluster and must be removed manually
* Each disk will be converted to a single `PersistentVolume`, RAID is not implemented to combine them

> L Series NVME volumes are 1.92 TB, the largest 20x instance supports 10 disks (see the [node type/size matrix](/modules/nodes/matrix.md))

---

### Multiple Clusters per Subnet

As documented in [CNI Options](#cni-options), the `Azure CNI` plugin officially supports multiple clusters in a subnet while `kubenet` does not.

However, given the IP requirements for Azure CNI (see [IP address availability and exhaustion](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#ip-address-availability-and-exhaustion)) it isn't really feasible to host more than one cluster in a subnet - unless it has a very large CIDR range **or** the clusters are very small (consider that even a 6 node cluster will exhaust a /24 subnet after consideration for node pool upgrades).

Also, while `kubenet` doesn't officially support it, testing hasn't yet highlighted any issues. Each cluster **must** have a unique `podnet_cidr` range so route table rules don't clash (increment the second octet for each cluster, e.g. `100.65.0.0/16`, `100.66.0.0/16` ...). However this **must not** be used in production given the current Azure support policy.

---

### Proximity Placement Groups

[Proximity Placement Groups](https://docs.microsoft.com/en-us/azure/aks/reduce-latency-ppg) aim to reduce network latency between nodes in the same availability zone by co-locating nodes physically close to one another. In the module this is managed by the `placement_group_key` string within the `node_pools` variable, with the following considerations and constraints:

- `placement_group_key` constraints - max 11 alphanumeric, lowercase characters (PPGs are max 12 characters, the zone id is appended)
- `placement_group_key` must be unique within the Resource Group hosting the AKS service
- it is only supported for zonal pools (`single_vmss` must be set to `false`)
- the same key _may_ be used for different pools to co-locate multiple node pools in the same placement group

__WARNING__: Proximity Placement Groups are not intended to be a general purpose tool to optimise network performance, their use must be carefully considered and discussed with a Solution Architect and potentially the Microsoft account team. By placing artificial topology constraints within an availability zone, there is a much higher chance nodes cannot be scheduled which could have significant impact if this occurs during certain events, e.g. node pool scale-out or upgrades.

<br>
<br>

## Service User Guide

How to interact with core services deployed by the module to support user services.

### Azure AD Pod Identity

Should a Kubernetes pod need to access the Azure API it will need appropriate authn/authz access.

The module deploys the `aad-pod-identity` service to support this via the following process:

* Create an Azure AD managed identity
* Assign the managed identity appropriate Azure RBAC permissions
* Configure `AzureIdentity` and `AzureIdentityBindings` resources to reference the managed identity
* Add the [aadpodidbinding](https://azure.github.io/aad-pod-identity/docs/demo/standard_walkthrough/#6-deployment-and-validation) label to pods with value set to the identity name

See the [Pod Identity walkthrough](https://azure.github.io/aad-pod-identity/docs/demo/standard_walkthrough/#2-create-an-identity-on-azure) from step 2 for implementation details.

> the `AzureIdentity` resource **must** be created in the same namespace as the pod

### Ingress

Ingress resources and controllers are used to route traffic into a cluster.

In early versions of Kubernetes the only way to achieve this was though a service of [type LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer), in some clouds this requires a discrete load balancer be deployed for each service which has significant cost implications. This doesn't apply to Azure, it adds a new IP for each service to an existing load balancer - however Ingress is still the most effective route to expose services for the following reasons.

* It integrates with `cert-manager` to automate [TLS Certificate](#tls-certificates) generation and renewals
* It integrates with `external-dns` to automate [DNS](#external-dns) record management
* It supports L7 routing based on host or paths (load balancers are L4 only)
* Some ingress controllers (*e.g. nginx*) also offer L4 support

By default the platform deploys an internal ingress class (`core-internal`) to expose services such as Prometheus and Grafana UIs. This shouldn't be used for user services unless there is only minimal internal ingress requirements, instead deploy a dedicated ingress tier and ingress controller.

See the [Ingress](/modules/core-config/modules/ingress_internal_core/README.md) documentation for implementation details.

---

### External DNS

The `external-dns` service will look for annotations on `service` resources or host definitions on `ingress` resources and update Azure DNS records accordingly. The most common use case will be ingress resources, the following ingress resource will create a `management-ui` DNS record in the `us-accurint-prod.azure.lnrsg.io` public zone.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: accurint-management-ui
  namespace: management-ui
spec:
  ingressClassName: public
  rules:
  - host: management-ui.us-accurint-prod.azure.lnrsg.io
    http:
      paths:
      - backend:
          service:
            name: management-ui
            port:
              number: 9001
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - management-ui.us-accurint-prod.azure.lnrsg.io
```

See [external-dns documentation](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/faq.md#how-do-i-specify-a-dns-name-for-my-kubernetes-objects) for more details.

---

### Coredns

The coredns module configures a configmap named `coredns-custom` via a `coredns` block in the `core_services_config` variable. This configures dns forwarders for the purpose of on-premise or cloud based dns resolution.

To configure coredns to forward DNS requests for custom domains to external resolvers, add the appropriate configuration to core_services_config as below.

```terraform
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    coredns = {
      forward_zones = {"b2b.regn.net" = "10.52.24.10 10.52.24.11"
                       "rbi.web.ds" = "10.52.24.10 10.52.24.11"
                       "risk.regn.net" = "10.239.0.135"
                      }
    }
    ...
  }
}
```

For more information please visit the modules [README.md](/modules/core-config/modules/coredns/README.md)

---

### TLS Certificates

The `cert-manager` service automates issuance and renewal of TLS certificates, the primary use case is for [ingress resources](https://cert-manager.io/docs/usage/ingress/).

The module implements a default `ClusterIssuer` (*letsencrypt-issuer*), which issues certificates from Let's Encrypt Production or Staging CAs. Ingress resource without the [cert-manager.io/cluster-issuer](https://cert-manager.io/docs/usage/ingress/) annotaion will be issued from the default issuer. In addition it implements a wildcard certificate, used by any ingress resource without a `secretName` in the `tls` configuration. This was implemented to mitigate [Let's Encrypt rate limits](https://letsencrypt.org/docs/rate-limits/) (50 certificates per week) against the top level domain.

The `external-dns` example above uses the default issuer and wildcard due to the absense of cert-manager annotation and `secretName` tls configuration respectively. If `secretName` is defined, a custom certificate will be issued to the service, however this counts against the top level domain (TLD) rate limits (in this case *lnrsg.io*) for the Let's Encrypt production CA.

Additional issuers can be added using module inputs, see the [cert-manager documentation](https://cert-manager.io/docs/) for more details.

> Let's Encrypt issuers **must not** be used for customer services, only internal services

---

### Network Policy

Kubenetes network policy is used to control traffic flow to and from pods in a cluster, internally and externally.

The module enables the Calico CNI plugin which supports [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

Both native Kubernetes Network Policies and extended [Calico Network Policies](https://docs.projectcalico.org/security/calico-network-policy) are supported. The service provides a Kubernetes Operator, which enables Calico Network Policies to be deployed natively through Kubernetes resources without requiring use of an external tool (`calicoctl`).

> be extrememly careful if deploying Calico [Global Network Policy](https://docs.projectcalico.org/reference/resources/globalnetworkpolicy) as this could render a cluster unusable

---

### Metrics & Alerts

The module deploys a Prometheus and Grafana stack which can be used to manage metrics and alerts.

The Prometheus, Grafana and AlertManager UIs are reachable via a built-in `core-internal` ingress class, see the [Ingress](/modules/core-config/modules/ingress_internal_core/README.md) documentation for implementation details and how to determine the URLs to access them.

The Prometheus Operator [supports integration](https://github.com/prometheus-operator/prometheus-operator#customresourcedefinitions) of ServiceMonitor, PodMonitor and PrometheusRule (and other) configuration via Custom Resource Definitions (CRDs), which provide a method to translate native Kubernetes manifests to Prometehus configuration and support dynamic updates. 

The core Prometheus service provides an opt-in approach for user services, should teams wish to use the core service to scrape their services or use custom rules. This is enabled by adding the `lnrs.io/monitoring-platform = core-prometheus` label to CRD resources.

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  labels:
    lnrs.io/monitoring-platform: core-prometheus
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - targetPort: 9198
    interval: 10s
```

The module provides a set of [built-in PrometheusRules](modules/core-config/modules/kube-prometheus-stack/resources) to alert on common issues with the cluster and resources.

See the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) documentation for more details.

---

### Azure Monitor Container Insights

The module can be configured to send logs and metrics to Log Analytics via the [Container Insights](https://docs.microsoft.com/en-us/azure/aks/monitor-aks#container-insights) add-on.

This is enabled by setting the `log_analytics_workspace_id` variable to a valid workspace which must already exist and be provisioned outwith the module. Note by setting this option you are consenting for Azure to deploy and fully manage a set of pods on the cluster to provide this integration, any issues must be raised directly with Azure support.

This integration duplicates some functionality that already exists within the module, for example the agents deploy another set of `fluent-bit` pods which will double IO load for log scraping. To avoid sending unnecessary data to Log Analytics (which could have a significant cost impact), carefully review and configure [agent settings](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-agent-config).

At a minimum we suggest excluding the kube-system and logging namespaces from the log collection settings for both stderr and stdout.

Example below shows a subset of the configmap to exclude the kube-system and logging namespaces:

```yaml
kind: ConfigMap
apiVersion: v1
data:
  schema-version:
    v1
  config-version:
    ver1
  log-data-collection-settings: |-
    [log_collection_settings]
       [log_collection_settings.stdout]
          enabled = true
          exclude_namespaces = ["kube-system", "logging"]
       [log_collection_settings.stderr]
          enabled = true
          exclude_namespaces = ["kube-system", "logging"]
metadata:
  name: container-azm-ms-agentconfig
  namespace: kube-system
```

