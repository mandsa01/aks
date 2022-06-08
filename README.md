# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard AKS clusters. This module takes a generic set of configuration options and creates a fully functional _Kubernetes_ cluster with a common set of services.

---

## Support Policy

This module is supported as a pattern by the core engineering team as long as the following constraints have been followed. This support **isn't** operational and by using this module you're agreeing that operational support will be provided to your end-users and the core engineering team will interact with your operational teams.

- Clusters **must** be updated periodically by updating this module within 4 weeks of the latest release.
  - Issues must be demonstrated on a cluster running the latest version of the module.
- Core engineering and architecture teams **only** support clusters deployed using this module.
  - Issues must be demonstrated by calling the module directly (_i.e. not nesting within multi-layer modules_).
- Issues should only be created by the cluster operators **after** they have confirmed that the problem hasn't already been documented, cluster users should work with the cluster operators if they have an issue.
  - Issues need to have context such as Kubernetes version, module version, region, etc.
  - Issues should have an example of how to replicate them on a test cluster unless not possible.
  - Issues not following this guidance will be closed.

## Help

Before using this module, the whole README should be read.

If you require further help, you can open an issue on this project or write a post on the [OG-RBA Kubernetes Working Group](https://teams.microsoft.com/l/team/19%3a27e66f24235b48dd8b14bf784f1a4e6a%40thread.skype/conversations?groupId=dc4762e6-314d-4645-9919-bff7cc54b91c&tenantId=9274ee3f-9425-4109-a27f-9fb15c10675d).

---

## Architecture

See [documentation](/docs) for system architecture, requirements and user guides for cluster services.

### Networking

A VNet could be shared with non-AKS resources, however there **must** be a pair of dedicated public and private subnets and a unique route table for each AKS cluster. While it is technically possible to host multiple AKS cluster node pools in a subnet, this is not recommended.

Subnet configuration, in particular sizing, will largely depend on the network plugin (CNI) used. See the [network model comparision](https://docs.microsoft.com/en-us/azure/aks/concepts-network#compare-network-models) for more information.

If the [dns_servers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network#dns_servers) attribute is set for the virtual network, the Azure DNS server "168.63.129.16" must be included in the list of values.

### DNS

Configuration for the DNS can be configured via inputs in the `core_services_config` variable.

For example, the module exposes ingress endpoints for core services such as Prometheus, Grafana and AlertManager UIs. The endpoints must be secured via TLS and DNS records must be published to Azure DNS for clients to resolve.

```yaml
  core_services_config = {
    cert_manager = {
      acme_dns_zones  = ["us-accurint-prod.azure.lnrsg.io"]
      default_issuer_name = letsencrypt # for production usage of letsencrypt
      }
    external_dns= {
      private_resource_group_name = "us-accurint-prod-dns-rg"
      private_zones = [ "us-accurint-prod.azure.lnrsg.io" ]
     #public_domain_filters = [ "us-accurint-prod.azure.lnrsg.io" ] ## use this if you use public dns zone
    }

    ingress_internal_core = {
      domain    = "us-accurint-prod.azure.lnrsg.io"
      public_dns = false # use true if you use public_domain_filters as above
    }
  }
```

- The `cert_manager` block specifies the **public zone** Let's Encrypt will use to validate the domain and its resource group.
- The `external_dns` block specifies domain(s) that user services can expose DNS records through and their resource group - all zones managed by _External DNS_ **must** be in a single resource group.
- The `ingress_internal_core` block specifies the domain to expose ingress resources to, consuming DNS/TLS services above.

It's very likely the same primary domain will be configured for all services, perhaps with _External DNS_ managing some additional domains. The resource group is a required input so the module can assign appropriate Azure role bindings. It is expected that in most cases all DNS domains will be hosted in a single resource group.

While _External DNS_ supports both public and private zones, in split-horizon setups only the private zone should be configured, otherwise both zones will be updated with service records. The only scenario for configuring both public and private zones of the same name is to migrate public records to private records. Once this is done, the public zone should be removed and records manually deleted in the public zone.

### Node Groups

The node group configuration (`node_group_templates`) allows a cluster to be created with multiple node groups that span multiple availability zones and can be configured with the specific required behaviour.

#### Node image upgrades

AKS supports upgrading the images on a node so you're up to date with the newest OS and runtime updates. AKS regularly provides new images with the latest updates, so it's beneficial to upgrade your node's images regularly for the latest AKS features. Linux node images are updated weekly, and Windows node images updated monthly. For more information please visit the official [Microsoft documentation](https://docs.microsoft.com/en-us/azure/aks/node-image-upgrade).

Within the AKS module we use two features to automatically upgrade the node images:

- [Automatic upgrade channel](https://docs.microsoft.com/en-us/azure/aks/node-image-upgrade)
- [Maintenance Window](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster#set-auto-upgrade-channel)

Unlike EKS there is no way of specifying the node image version via Terraform so we use the Automatic upgrade channel set to node-image. this enables automatic node image upgrades outside of Terraform. Note kubernetes patch, minor and major versions are controlled separately. Combining the automatic upgrade channel with a maintenance window gives us the ability to control when the upgrades take place.

The module sets a default of a maintenance window of Tuesdays, Wednesdays and Thursdays between the hours of 10am and 4pm. The default maintenance window can be overwritten in the client side code, for an example please visit the [central documentation](https://gitlab.b2b.regn.net/kubernetes/kubernetes-core/-/blob/master/README.md).

#### Node Sizes

Node sizes are based on the number of CPUs, with the other resources being dependent on the node type; not all node types support all sizes.

When creating persistent volumes in Azure, make sure you use a size supported by azure disk. This applies to [standard](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-types#standard-ssd-size) and [premium](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-types#premium-ssd-size) SSD sizes.

|   **Name** | **CPU Count** |
| ---------: | ------------: |
|    `large` |           `2` |
|   `xlarge` |           `4` |
|  `2xlarge` |           `8` |
|  `4xlarge` |          `16` |
|  `8xlarge` |          `32` |
| `12xlarge` |          `48` |
| `16xlarge` |          `64` |
| `18xlarge` |          `72` |
| `20xlarge` |          `80` |
| `24xlarge` |          `96` |
| `26xlarge` |         `104` |

#### Node Types

Node types describe the purpose of the node and maps down to the underlaying [Azure virtual machines](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes). Select your node type for the kind of workloads you expect to be running, as a rule of thumb use `gp` unless you have additional requirements.

Due to the availability issues with specific Azure VMs when choosing a node type you also need to select the version; newer versions may well be less available in popular regions.

All the nodes provisioned by the module support permium storage.

##### General Purpose

[General purpose](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general) nodes, `gp` & `gpd`, offer a good balance of compute and memory. If you need a local NVMe drive `gpd` provides this.

| **Type** | **Version** | **VM Type**                                                                                     | **Sizes**                                                                               |
| -------- | ----------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `gp`     | `v1`        | [Dsv4](https://docs.microsoft.com/en-us/azure/virtual-machines/dv4-dsv4-series#dsv4-series)     | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`             |
| `gp`     | `v2`        | [Dsv5](https://docs.microsoft.com/en-us/azure/virtual-machines/dv5-dsv5-series#dsv5-series)     | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |
| `gpd`    | `v1`        | [Ddsv4](https://docs.microsoft.com/en-us/azure/virtual-machines/ddv4-ddsv4-series#ddsv4-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`             |
| `gpd`    | `v2`        | [Ddsv5](https://docs.microsoft.com/en-us/azure/virtual-machines/ddv5-ddsv5-series#ddsv5-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `24xlarge` |

##### Memory Optimised

[Memory optimised](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-memory) nodes, `mem` & `memd`, offer a higher memory to CPU ration than general purpose nodes. If you need a local NVMe drive `memd` provides this.

| **Type** | **Version** | **VM Type**                                                                                     | **Sizes**                                                                                           |
| -------- | ----------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `mem`    | `v1`        | [Esv4](https://docs.microsoft.com/en-us/azure/virtual-machines/ev4-esv4-series#esv4-series)     | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`                         |
| `mem`    | `v2`        | [Esv5](https://docs.microsoft.com/en-us/azure/virtual-machines/ev5-esv5-series#esv5-series)     | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge`, `24xlarge` & `26xlarge` |
| `memd`   | `v1`        | [Edsv4](https://docs.microsoft.com/en-us/azure/virtual-machines/edv4-edsv4-series#edsv4-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge` & `16xlarge`                         |
| `memd`   | `v2`        | [Edsv5](https://docs.microsoft.com/en-us/azure/virtual-machines/edv5-edsv5-series#edsv5-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge`, `24xlarge` & `26xlarge` |

##### Compute Optimised

[Compute optimised](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-compute) nodes, `cpu`, offer a higher CPU to memory ratio than general purpose nodes.

| **Type** | **Version** | **VM Type**                                                                 | **Sizes**                                                                               |
| -------- | ----------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `cpu`    | `v1`        | [Fsv2](https://docs.microsoft.com/en-us/azure/virtual-machines/fsv2-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `18xlarge` |

##### Storage Optimised

[Storage optimised](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-storage) nodes, `stor`, offer higher disk throughput and IO than general purpose nodes.

| **Type** | **Version** | **VM Type**                                                                 | **Sizes**                                                                               |
| -------- | ----------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `stor`   | `v1`        | [Lsv2](https://docs.microsoft.com/en-us/azure/virtual-machines/lsv2-series) | `large`, `xlarge`, `2xlarge`, `4xlarge`, `8xlarge`, `12xlarge`, `16xlarge` & `20xlarge` |

---

## Usage

This module is expected to be referenced by it's major version (e.g. `v1`) and run regularly (at least every 4 weeks) to keep the cluster configuration up to date.

### Core Service Configuration

The core service configuration (`core_services_config`) allows the customisation of the core cluster services. All core services run on a dedicated system node group reserved only for these services, although DaemonSets will be scheduled on all cluster nodes.

### Auto-scaling

Cluster node groups will be auto scaled by using the [AKS Cluster Autoscaler](https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler).

### Logging

Cluster logs are collected on the nodes using _Fluent Bit_ and are then aggregated into the stateful _Fluentd_ service running in-cluster. These logs can be manipulated and shipped anywhere based on custom _Fluentd_ configuration. If your application creates JSON log lines the fields of this object are extracted, otherwise there is a `log` field with the application log data as a string; for JSON logging we suggest using `msg` for the log text field.

All logs collected from running pods have a `kube` tag and additional fields extracted from the Kubernetes metadata, please note that using [Kubernetes common labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) makes the log fields more meaningful.

Pods annotated with the `fluentbit.io/exclude: "true"` annotation wont have their logs collected as part of the cluster logging system, this shouldn't be used unless you have an alternative way of ensuring that you're in compliance.

Pods annotated with the `lnrs.io/loki-ignore: "true"` annotation wont have their logs aggregated in the cluster _Loki_, this is advised against as it reduces log visibility but can be used to gradually integrate cluster services with _Loki_.

As well as custom _Fluentd_ configuration it is also possible to provide a custom _Fluentd_ image if you need additional capabilities as long as the image has the required default plugins.

### Metrics

Cluster metrics are collected by Prometheus and visualised in Grafana. These metrics can be remotely written out to an external system.

### Alerts

Cluster alerts default to being ignored but can be fully customised with receivers and routes.

### Ingress

All traffic being routed into a cluster should be configured using an `Ingress` resources backed by an ingress controller and should **NOT** be configured directly as a `Service` resource of `LodBalancer` type (this is what the ingress controllers do behind the scenes). There are a number of different ingress controller supported by _Kubernetes_ but it is strongly recommended to use an ingress controller backed by an official Terraform module to install. All ingress traffic should enter the cluster onto nodes specifically provisioned for ingress without any other workload on them.

Out of the box the cluster supports automatically generating certificates with _Cert Manager_ and DNS records with _External DNS_ from `Ingress` resources.

#### Ingress Controllers

The following official Terraform modules for ingress controllers are supported by the core engineering team and have been tested on AKS (please note that these are currently hosted on GitLab so should be copied into the `./modules` folder in your workspace and checked in).

- [K8s Ingress NGINX Terraform Module](https://gitlab.b2b.regn.net/terraform/official-modules/k8s/terraform-lnrs-k8s-ingress-nginx)

#### Ingress Nodes

Ingress nodes mush have the `lnrs.io/tier: ingress` label and the `ingress=true:NoSchedule` taint to enable the ingress controller(s) to be scheduled and to isolate ingress traffic from other pods. You can also add additional labels and taints to keep specific ingress traffic isolated to it's own nodes. As ingress traffic is stateless a single node group can be used to span multiple zones by setting `single_group = true`.

An example of an ingress node group.

```terraform
locals {
  ingress_node_group = {
    {
      name                = "ingress"
      node_os             = "ubuntu"
      node_type           = "gp"
      node_type_version   = "v1"
      node_size           = "large"
      single_group        = true
      min_capacity        = 3
      max_capacity        = 6
      placement_group_key = null
      labels = {
        "lnrs.io/tier" = "ingress"
      }
      taints = [{
        key    = "ingress"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      tags   = {}
    }
  }
}
```

#### Ingress Internal Core

By default the platform deploys an internal `IngressClass`, named `core-internal`, to expose services such as _Prometheus_ and _Grafana_ UIs. This ingress shouldn't be used for user services but can be used for other internal dashboards; for user services instead deploy a dedicated ingress controller with it's own `IngressClass`.

### Upgrading

Core service and node upgrades are automated as part of running this module and don't require any user interaction. Kubernetes minor version upgrades are supported by the module as long as the upgrade is only to the next minor version and the cluster has had the latest module version run against it.

### Regular Upgrade Steps

The following steps should be followed to automatically upgrade a clusters configuration.

- Re-run `terraform plan` with no code changes and the module reference set to a major version tag such as `v1`
- Review changes
- Apply updated configuration if there are any changes

### Kubernetes Minor Version Upgrade Steps

The following steps should be followed to upgrade a cluster's Kubernetes minor version.

- Follow the regular upgrade steps first
- Increment the _cluster_version_ by a single minor version e.g. `1.21` -> `1.22`
- Run `terraform plan`
- Review changes
- Apply changes

### Connecting to the Cluster

AKS clusters created by this module use [Azure AD authentication](https://docs.microsoft.com/en-us/azure/aks/managed-aad) and don't create local accounts. To connect to an AKS cluster after it's been created follow you can run the following commands; assuming that you have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed, you are logged in.

```shell
az aks install-cli
```

```shell
az aks get-credentials --resource-group "${RESOURCE_GROUP_NAME}" --name "${CLUSTER_NAME}"
kubelogin convert-kubeconfig -l azurecli
```

### Examples

- [Default example](./examples/default/)
- [DSG example](./examples/dsg/)
- [Windows example](./examples/windows/)

---

## Experimental Features

> **Info**
> Experimental features are not officially supported and do not follow SemVer like the rest of this module; use them at your own risk.

Experimental features allow end users to try out new functionality which isn't stable in the context of a stable module release, they are enabled by setting the required variables on the `experimental` module variable.

### AAD Pod Identity Finalizer Wait

If your cluster isn't being destroyed cleanly due to stuck AAD Pod Identity resources you can increase the time we wait before uninstalling the chart by setting `experimental = { aad_pod_identity_finalizer_wait = "300s" }`.

### Control Plane Log Categories

This experimental feature allows you to influence the volume of control plane logs collected by specifying the set of control plane log categories you wish to be captured. This is achieved by setting `workspace_log_categories` for the log categories sent to the module created log analytics workspace and setting `storage_log_categories` if you've passed in an additional storage account. The available values are one of `all`, `recommended` or `limited`; for example setting `experimental = { workspace_log_categories = "recommended", storage_log_categories = "all" }` will send the recommended set of logs to the log analytics workspace and all of the logs to object storage.

By default and if these values aren't specified the recommended log categories will be collected.

| **Value**     | **Log Categories**                                                                                                                                                                                                                  |
| :------------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `all`         | `["kube-apiserver", "kube-audit", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]`       |
| `recommended` | `["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]` |
| `limited`     | `["kube-apiserver", "kube-controller-manager", "cloud-controller-manager", "guard"]`                                                                                                                                                |

### OMS Agent Support

This module supports enabling the OMS agent as it needs to be done when the cluster is created; but the operation of the agent is not managed by the module and needs to be handled by the cluster operators separately. All core namespaces should be excluded by the cluster operator, especially the _logging_ namespace, unless they are specifically wanted.

To enable OMS agent support you need to set `experimental = { oms_agent = true, oms_log_analytics_workspace_id = "my-workspace-id" }`.

If the log analytics workspace is created in a different resource group to the cluster, `experimental.oms_log_analytics_workspace_different_resource_group` must also be set to `true`.

### Windows Node Support

> **Important**
> Teams must seek approval from their business unit Architect and IOG Architecture before using Windows node pools.

Windows Node support is **best effort** and is currently significantly limited, Windows node pools do not include platform `daemonsets` such as the Prometheus metrics exporter, Fluent Bit log collection or Azure AD Pod Identity. In the interim it is expected teams provide their own support for these features, e.g. use Azure Container Insights for log collection. Services provided by the AKS platform **should** work but have not been tested, including `kube-proxy`, CSI drivers and Calico network policy.

There may be other requirements or specific configuration required for Windows nodes, yet to be identified. We encourage teams to identify, report and contribute code and documentation to improve support going forward.

To enable Windows support you need to set `experimental = { windows_support = true }`.

---

## Requirements

This module requires the following versions to be configured in the workspace `terraform {}` block.

### Terraform

| **Version** |
| :---------- |
| `>= 1.0.0`  |

### Providers

| **Name**                                                                                    | **Version** |
| :------------------------------------------------------------------------------------------ | :---------- |
| [hashicorp/azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest)       | `>= 3.1.0`  |
| [hashicorp/helm](https://registry.terraform.io/providers/hashicorp/helm/latest)             | `>= 2.5.1`  |
| [gavinbunney/kubectl](https://registry.terraform.io/providers/gavinbunney/kubectl/latest)   | `>= 1.14.0` |
| [hashicorp/kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest) | `>= 2.11.0` |
| [hashicorp/random](https://registry.terraform.io/providers/hashicorp/random/latest)         | `>= 3.1.0`  |
| [scottwinkler/shell](https://registry.terraform.io/providers/scottwinkler/shell/latest)     | `>= 1.7.10` |
| [hashicorp/time](https://registry.terraform.io/providers/hashicorp/time/latest)             | `>= 0.7.2`  |

---

## Variables

| **Variable**                          | **Description**                                                                                                                                                                       | **Type**                                   | **Default**       |
| :------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------- | :---------------- |
| `azure_env`                           | Azure cloud environment type, `public` & `usgovernment` are supported.                                                                                                                | `string`                                   | `"public"`        |
| `location`                            | Azure location to target.                                                                                                                                                             | `string`                                   | `null`            |
| `resource_group_name`                 | Name of the resource group to create resources in, some resources will be created in a separate AKS managed resource group.                                                           | `string`                                   | `null`            |
| `cluster_name`                        | Name of the Azure Kubernetes Service managed cluster to create, also used as a prefix in names of related resources. This must be lowercase and contain the pattern `aks-{ordinal}`.  | `string`                                   | `null`            |
| `cluster_version`                     | Kubernetes version to use for the Azure Kubernetes Service managed cluster, versions `1.22` & `1.21` are supported.                                                                   | `string`                                   | `null`            |
| `network_plugin`                      | Kubernetes network plugin, `kubenet` & `azure` are supported.                                                                                                                         | `string`                                   | `"kubenet"`       |
| `sku_tier_paid`                       | If the cluster control plane SKU tier should be paid or free. The paid tier has a financially-backed uptime SLA.                                                                      | `bool`                                     | `null`            |
| `cluster_endpoint_public_access`      | Indicates whether or not the Azure Kubernetes Service managed cluster public API server endpoint is enabled.                                                                          | `bool`                                     | `null`            |
| `cluster_endpoint_access_cidrs`       | List of CIDR blocks which can access the Azure Kubernetes Service managed cluster API server endpoint.                                                                                | `list(string)`                             | `null`            |
| `virtual_network_resource_group_name` | Name of the resource group containing the virtual network.                                                                                                                            | `string`                                   | `null`            |
| `virtual_network_name`                | Name of the virtual network to use for the cluster.                                                                                                                                   | `string`                                   | `null`            |
| `subnet_name`                         | Name of the AKS subnet in the virtual network.                                                                                                                                        | `string`                                   | `null`            |
| `route_table_name`                    | Name of the AKS subnet route table.                                                                                                                                                   | `string`                                   | `null`            |
| `dns_resource_group_lookup`           | Lookup from DNS zone to resource group name.                                                                                                                                          | `map(string)`                              | `null`            |
| `podnet_cidr_block`                   | CIDR range for pod IP addresses when using the `kubenet` network plugin, if you're running more than one cluster in a virtual network this value needs to be unique.                  | `string`                                   | `"100.65.0.0/16"` |
| `admin_group_object_ids`              | AD Object IDs to be added to the cluster admin group. The identity running the module should either be in a group passed in here or configured as a cluster admin outside the module. | `list(string)`                             | `[]`              |
| `azuread_clusterrole_map`             | Map of Azure AD user and group IDs to configure via Kubernetes ClusterRoleBindings.                                                                                                   | `object` ([Appendix A](#appendix-a))       | `{}`              |
| `node_group_templates`                | Templates describing the requires node groups.                                                                                                                                        | `object` ([Appendix B](#appendix-b))       | `null`            |
| `core_services_config`                | Core service configuration.                                                                                                                                                           | `any` ([Appendix D](#appendix-d))          | `null`            |
| `logging_storage_account_id`          | Optional ID of a storage account to add cluster logs to.                                                                                                                              | `string`                                   | `""`              |
| `maintenance_window_offset`           | Maintenance window offset to utc.                                                                                                                                                     | `number`                                   | `null`            |
| `maintenance_window_allowed_days`     | List of allowed days covering the maintenance window.                                                                                                                                 | `list(string)`                             | `[]`              |
| `maintenance_window_allowed_hours`    | List of allowed hours covering the maintenance window.                                                                                                                                | `list(number)`                             | `[]`              |
| `maintenance_window_not_allowed`      | List of not allowed block objects consisting of start and end times in rfc3339 format. A not allowed block takes priority if it overlaps an allowed blocks in a maintenance window.   | `list(object)` ([Appendix M](#appendix-m)) | `[]`              |
| `tags`                                | Tags to apply to all resources.                                                                                                                                                       | `map(string)`                              | `{}`              |
| `experimental`                        | Configure experimental features.                                                                                                                                                      | `any`                                      | `{}`              |

### Appendix A

Specification for the `azuread_clusterrole_map` object.

| **Variable**           | **Description**                                                                           | **Type**      | **Default** |
| :--------------------- | :---------------------------------------------------------------------------------------- | :------------ | :---------- |
| `cluster_admin_users`  | Users to add to the cluster admin role, identifier as the key and group ID as the value.  | `map(string)` | `null`      |
| `cluster_view_users`   | Users to add to the cluster view role, identifier as the key and group ID as the value.   | `map(string)` | `null`      |
| `standard_view_users`  | Users to add to the standard view role, identifier as the key and group ID as the value.  | `map(string)` | `null`      |
| `standard_view_groups` | Groups to add to the standard view role, identifier as the key and group ID as the value. | `map(string)` | `null`      |

### Appendix B

Specification for the `node_group_templates` objects.

| **Variable**          | **Description**                                                                                                                                                                                                                                                                                                          | **Type**                             | **Default** |
| :-------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------- | :---------- |
| `name`                | User defined component of the node group(s) name.                                                                                                                                                                                                                                                                        | `string`                             | `null`      |
| `node_os`             | OS to use for the node group(s), `ubuntu` & `windows` are supported, [Windows node support](#windows-node-support) is experimental and needs manually enabling.                                                                                                                                                          | `string`                             | `null`      |
| `node_type`           | Node type to use, one of `gp`, `gpd`, `mem`, `memd`, `cpu` or `stor`. See [node types](#node-types) for more information.                                                                                                                                                                                                | `string`                             | `null`      |
| `node_type_version`   | The version of the node type to use. See [node types](#node-types) for more information.                                                                                                                                                                                                                                 | `string`                             | `null`      |
| `node_size`           | Size of the instance to create in the node group(s). See [node sizes](#node-sizes) for more information.                                                                                                                                                                                                                 | `string`                             | `null`      |
| `single_group`        | If this template represents a single node group spanning multiple zones or a node group per cluster zone.                                                                                                                                                                                                                | `bool`                               | `null`      |
| `min_capacity`        | Minimum number of nodes in the node group(s), this needs to be divisible by the number of subnets in use.                                                                                                                                                                                                                | `number`                             | `null`      |
| `max_capacity`        | Maximum number of nodes in the node group(s), this needs to be divisible by the number of subnets in use.                                                                                                                                                                                                                | `number`                             | `null`      |
| `placement_group_key` | If specified the node group will be added to a proximity placement group created for the key in a zone, `single_group` must be `false`. The key must be lowercase, alphanumeric, maximum 11 characters, please refer to the [documentation](/docs/README.md#proximity-placement-groups) for warnings and considerations. | `string`                             | `null`      |
| `labels`              | Additional labels for the node group(s). It is suggested to set the `lnrs.io/tier` label.                                                                                                                                                                                                                                | `map(string)`                        | `null`      |
| `taints`              | Taints for the node group(s). For ingress node groups the `ingress` taint should be set to `NO_SCHEDULE`.                                                                                                                                                                                                                | `object` ([Appendix C](#appendix-c)) | `null`      |
| `tags`                | User defined component of the node group name.                                                                                                                                                                                                                                                                           | `map(string)`                        | `null`      |

### Appendix C

Specification for the `node_group_templates.taints` objects.

| **Variable** | **Description**                                                                           | **Type** | **Default** |
| :----------- | :---------------------------------------------------------------------------------------- | :------- | :---------- |
| `key`        | The key of the taint. Maximum length of 63.                                               | `string` | `null`      |
| `value`      | The value of the taint. Maximum length of 63.                                             | `string` | `null`      |
| `effect`     | The effect of the taint. Valid values: `NO_SCHEDULE`, `NO_EXECUTE`, `PREFER_NO_SCHEDULE`. | `string` | `null`      |

### Appendix D

Specification for the `core_services_config` object.

| **Variable**            | **Description**                      | **Type**                          | **Default** |
| :---------------------- | :----------------------------------- | :-------------------------------- | :---------- |
| `alertmanager`          | Alertmanager configuration.          | `any` ([Appendix E](#appendix-e)) | `null`      |
| `cert_manager`          | Cert Manager configuration.          | `any` ([Appendix F](#appendix-f)) | `null`      |
| `coredns`               | CoreDNS configuration.               | `any` ([Appendix G](#appendix-g)) | `null`      |
| `external_dns`          | ExternalDNS configuration.           | `any` ([Appendix H](#appendix-h)) | `null`      |
| `fluentd`               | Fluentd configuration.               | `any` ([Appendix I](#appendix-i)) | `null`      |
| `grafana`               | Grafana configuration.               | `any` ([Appendix J](#appendix-j)) | `null`      |
| `ingress_internal_core` | Ingress internal-core configuration. | `any` ([Appendix K](#appendix-k)) | `null`      |
| `prometheus`            | Prometheus configuration.            | `any` ([Appendix L](#appendix-l)) | `null`      |

### Appendix E

Specification for the `core_services_config.alertmanager` object.

| **Variable** | **Description**                                                                               | **Type** | **Required** |
| :----------- | :-------------------------------------------------------------------------------------------- | :------- | :----------- |
| `smtp_host`  | SMTP host to send alert emails.                                                               | `string` | **Yes**      |
| `smtp_from`  | SMTP from address for alert emails.                                                           | `string` | **Yes**      |
| `receivers`  | [Receiver configuration](https://prometheus.io/docs/alerting/latest/configuration/#receiver). | `any`    | No           |
| `routes`     | [Route configuration](https://prometheus.io/docs/alerting/latest/configuration/#route).       | `any`    | No           |

### Appendix F

Specification for the `core_services_config.cert_manager` object.

| **Variable**          | **Description**                                                | **Type**       | **Required** |
| :-------------------- | :------------------------------------------------------------- | :------------- | :----------- |
| `acme_dns_zones`      | DNS zones that _ACME_ issuers can manage certificates for.     | `list(string)` | No           |
| `additional_issuers`  | Additional issuers to install into the cluster.                | `map(any)`     | No           |
| `default_issuer_kind` | Kind of the default issuer.                                    | `string`       | No           |
| `default_issuer_name` | Name of the default issuer , use `letsencrypt` for prod certs. | `string`       | No           |

### Appendix G

Specification for the `core_services_config.coredns` object.

| **Variable**    | **Description**                                                          | **Type**      | **Required** |
| :-------------- | :----------------------------------------------------------------------- | :------------ | :----------- |
| `forward_zones` | Map of DNS zones and DNS server IP addresses to forward DNS requests to. | `map(string)` | No           |

### Appendix H

Specification for the `core_services_config.external_dns` object.

| **Variable**             | **Description**                                                                                                 | **Type**       | **Required** |
| :----------------------- | :-------------------------------------------------------------------------------------------------------------- | :------------- | :----------- |
| `additional_sources`     | Additional _Kubernetes_ objects to be watched.                                                                  | `list(string)` | No           |
| `private_domain_filters` | Domains that can have DNS records created for them, these must be set up in the VPC as private hosted zones.    | `list(string)` | No           |
| `public_domain_filters`  | Domains that can have DNS records created for them, these must be set up in the account as public hosted zones. | `list(string)` | No           |

### Appendix I

Specification for the `core_services_config.fluentd` object.

| **Variable**       | **Description**                                                                                                                    | **Type**      | **Required** |
| :----------------- | :--------------------------------------------------------------------------------------------------------------------------------- | :------------ | :----------- |
| `image_repository` | Custom image repository to use for the _Fluentd_ image, `image_tag` must also be set.                                              | `map(string)` | No           |
| `image_tag`        | Custom image tag to use for the _Fluentd_ image, `image_repository` must also be set.                                              | `map(string)` | No           |
| `additional_env`   | Additional environment variables.                                                                                                  | `map(string)` | No           |
| `debug`            | If `true` all logs are printed to stdout.                                                                                          | `bool`        | No           |
| `filters`          | [Fluentd filter configuration](https://docs.fluentd.org/filter), can be multiple `<filter>` blocks.                                | `string`      | No           |
| `routes`           | _Fluentd_ [fluent-plugin-route](https://github.com/tagomoris/fluent-plugin-route) configuration, can be multiple `<route>` blocks. | `string`      | No           |
| `outputs`          | [Fluentd output configuration](https://docs.fluentd.org/output), can be multiple `<label>` blocks referencing the routes.          | `string`      | No           |

### Appendix J

Specification for the `core_services_config.grafana` object.

| **Variable**              | **Description**                | **Type**       | **Required** |
| :------------------------ | :----------------------------- | :------------- | :----------- |
| `admin_password`          | Admin password.                | `string`       | No           |
| `additional_data_sources` | Additional data sources.       | `list(any)`    | No           |
| `additional_plugins`      | Additional plugins to install. | `list(string)` | No           |

### Appendix K

Specification for the `core_services_config.ingress_internal_core` object.

| **Variable**       | **Description**                                                                     | **Type**       | **Required** |
| :----------------- | :---------------------------------------------------------------------------------- | :------------- | :----------- |
| `domain`           | Internal ingress domain.                                                            | `string`       | **Yes**      |
| `subdomain_suffix` | Suffix to add to internal ingress subdomains, if not set cluster name will be used. | `string`       | No           |
| `lb_source_cidrs`  | CIDR blocks of the IPs allowed to connect to the internal ingress endpoints.        | `list(string)` | No           |
| `public_dns`       | If the internal ingress DNS should be public or private.                            | `bool`         | No           |

### Appendix L

Specification for the `core_services_config.prometheus` object.

| **Variable**   | **Description**                     | **Type**       | **Required** |
| :------------- | :---------------------------------- | :------------- | :----------- |
| `remote_write` | Remote write endpoints for metrics. | `list(string)` | No           |

### Appendix M

Specification for the `maintenance_window_not_allowed` object.

| **Variable** | **Description**                                                             | **Type** | **Required** |
| :----------- | :-------------------------------------------------------------------------- | :------- | :----------- |
| `start`      | Start time for the not allowed maintenance window block in rfc 3339 format. | `string` | No           |
| `end`        | End time for the not allowed maintenance window block in rfc 3339 format.   | `string` | No           |

---

## Outputs

| **Variable**                                 | **Description**                                                                                 | **Type**       |
| :------------------------------------------- | :---------------------------------------------------------------------------------------------- | :------------- |
| `cluster_id`                                 | Azure Kubernetes Service (AKS) managed cluster ID.                                              | `string`       |
| `cluster_fqdn`                               | FQDN of the Azure Kubernetes Service managed cluster.                                           | `string`       |
| `cluster_endpoint`                           | Endpoint for the Azure Kubernetes Service managed cluster API server.                           | `string`       |
| `cluster_certificate_authority_data`         | Base64 encoded certificate data for the Azure Kubernetes Service managed cluster API server.    | `string`       |
| `control_plane_log_analytics_workspace_id`   | ID of the default log analytics workspace created for control plane logs.                       | `string`       |
| `control_plane_log_analytics_workspace_name` | Name of the default log analytics workspace created for control plane logs.                     | `string`       |
| `node_resource_group_name`                   | Auto-generated resource group which contains the resources for this managed Kubernetes cluster. | `string`       |
| `effective_outbound_ips`                     | Base64 encoded certificate data for the Azure Kubernetes Service managed cluster API server.    | `list(string)` |
| `cluster_identity`                           | User assigned identity used by the cluster.                                                     | `object`       |
| `kubelet_identity`                           | Kubelet identity.                                                                               | `object`       |
| `cert_manager_identity`                      | Identity that Cert Manager uses.                                                                | `object`       |
| `external_dns_private_identity`              | Identity that private ExternalDNS uses.                                                         | `object`       |
| `external_dns_public_identity`               | Identity that public ExternalDNS uses.                                                          | `object`       |
| `fluentd_identity`                           | Identity that Fluentd uses.                                                                     | `object`       |
| `grafana_identity`                           | Identity that Grafana uses.                                                                     | `object`       |
| `oms_agent_identity`                         | Identity that the OMS agent uses.                                                               | `object`       |
| `windows_config`                             | Windows configuration.                                                                          | `object`       |
