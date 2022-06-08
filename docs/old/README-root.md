# Azure Kubernetes Service (AKS) Terraform Module

## Overview

This module is designed to provide a simple and opinionated way to build standard AKS clusters and is based on the open-source [terraform-azurerm-kubernetes](https://github.com/Azure-Terraform/terraform-azurerm-kubernetes) module. This module takes a set of configuration options and creates a fully functional Kubernetes cluster with a common set of services.

---

## Support Policy

Support and use of this module.

- Clusters **must** be updated periodically by updating this module within 1 month of the latest release
- For the most stable experience, upgrade through sequential minor versions in turn
  - While upgrades through non-consecutive version **should** work, the core team don't test this
- Core engineering and architecture teams only support clusters deployed using this module
  - It is not supported to use the upstream open-source module directly, or any other method
  - Issues must be demonstrated by calling the module directly (_i.e. not nesting within multi-layer modules_)

<br />

### Windows Support

Teams **must** seek approval from their business unit Architect **and** IOG Architecture before using Windows node pools.

Windows support is currently limited, Windows node pools do not include platform `daemonsets` such as the Prometheus metrics exporter, Fluent-bit log collection or Azure AD Pod Identity. In the interim it is expected teams provide their own support for these features, e.g. use Azure Container Insights for log collection. Services provided by the AKS platform **should** work but have not been tested, including `kube-proxy`, CSI drivers and Calico network policy.

There may be other requirements or specific configuration required for Windows nodes, yet to be identified. We encourage teams to identify, report and contribute code and documentation to improve support going forward. We plan on providing an equally supported module for Windows, however, we are still establishing testing procedures and identifying the appropriate level of resource required to achieve this.

---

## Requirements

See [documentation](/docs) for system architecture, requirements and user guides for cluster services.

---

## Usage

This module is designed to provide a standard set of defaults for all node pools and optimized instance type selection for a given size.

See [examples](/examples) for general usage and how to integrate AKS with other **mandatory** IOG modules (_e.g. Vnet, naming_).

<details>
<summary markdown="span">AKS cluster with private and ingress node pools</summary>
<br />
A standalone configuration simply to highlight minimum requirements, plus describe core object structures.

DO NOT copy this directly, see the examples folder for production cluster setup.
<br />

```terraform
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks?ref=v1"

  cluster_name    = "ioa-aks-1"
  cluster_version = "1.21"
  sku_tier        = "Paid"
  
  location            = "eastus"
  resource_group_name = "ioa-aks-1-rg"
  
  virtual_network = {
    subnets = {
      private = { id = "/subscriptions/ff83a9d2-8d6e-4c4a-8b34-641163f8c99f/resourceGroups/AKS-1-Vnet/providers/Microsoft.Network/virtualNetworks/AKS-1-vnet/subnets/private" }
      public  = { id = "/subscriptions/ff83a9d2-8d6e-4c4a-8b34-641163f8c99f/resourceGroups/AKS-1-Vnet/providers/Microsoft.Network/virtualNetworks/AKS-1-vnet/subnets/public" }
    }
    route_table_id = "/subscriptions/ff83a9d2-8d6e-4c4a-8b34-641163f8c99f/resourceGroups/AKS-1-Vnet/providers/Microsoft.Network/routeTables/AKS-1-route-table"
  }

  node_pools = [
    {
      name               = "workers"
      single_vmss        = false
      public             = false
      placement_group_key = ""
      node_type          = "x64-gp-v1"
      node_size          = "medium"
      min_capacity       = "3"
      max_capacity       = "6"
      taints = []
      labels = {
        "lnrs.io/tier" = "standard"
      }
      tags = {}
    }
  ]
  ingress_node_pool = true

  core_services_config = {
    alertmanager = {
      smtp_host = "smtp.lexisnexisrisk.com:25"
      smtp_from = "ioa-eks-1@lexisnexisrisk.com"
      receivers = [{ name = "alerts", email_configs = [{ to = "ioa-sre@lexisnexisrisk.com", require_tls = false }]}]
    }
  
    cert_manager = {
      dns_zones = { 
        "ioa.useast.azure.lnrsg.io" = "ioa-dns-zones-rg"
      }
    }

    external_dns = {
      public_zones               = [ "ioa.useast.azure.lnrsg.io" ]
      public_resource_group_name = "ioa-dns-zones-rg"
    }

    ingress_core_internal = {
      domain = "ioa.useast.azure.lnrsg.io"
    }
  }
  
  azuread_clusterrole_map = {
    cluster_admin_users  = {
      "James Murtagh" = "d76d0bbd-3243-47e2-bdff-b4a8d4f2b6c1"
    }
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }

  tags = {
    "my-tag" = "tag value"
  }
}
```

</details>
<br />

- Refer to [CHANGELOG.md](CHANGELOG.md) to review significant changes within each release version
- Refer to [UPGRADE.md](/UPGRADE.md) for module upgrade instructions and troubleshooting steps

---

## Terraform

| **Version** |
| :---------- |
| `>= 1.0.0`  |

## Providers

| **Name**     | **Version** |
| :----------- | :---------- |
| `azurerm`    | `>= 2.71.0` |
| `helm`       | `>= 2.4.1`  |
| `kubectl`    | `>= 1.13.1` |
| `kubernetes` | `>= 2.6.1`  |
| `random`     | `>= 3.1.0`  |
| `time`       | `>= 0.7.1`  |

## Inputs

| **Variable**                      | **Description**                                                                                                                                                                                                                                                                                   | **Type**                                 | **Default**          | **Required** |
| :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------- | :------------------- | :----------: |
| `api_server_authorized_ip_ranges` | Public IP or CIDR ranges to apply as a whitelist to the K8S API server, if not set defaults to `0.0.0.0/0`.                                                                                                                                                                                       | `map(string)`                            | `nil`                |     `no`     |
| `azure_environment`               | Azure Cloud Environment.  `AzurePublicCloud` & `AzureUSGovernmentCloud` are supported.                                                                                                                                                                                                            | `string`                                 | `"AzurePublicCloud"` |     `no`     |
| `azuread_clusterrole_map`         | Azure AD Users and Groups to assign to Kubernetes cluster roles.                                                                                                                                                                                                                                  | `object(map(string))` _(see appendix a)_ | `{}`                 |     `no`     |
| `cluster_name`                    | Name of the AKS cluster, also used as a prefix in names of related resources.                                                                                                                                                                                                                     | `string`                                 | `nil`                |    `yes`     |
| `cluster_version`                 | The Kubernetes minor version. Versions `1.19`, `1.20` & `1.21` supported.                                                                                                                                                                                                                         | `string`                                 | `"1.21"`             |     `no`     |
| `core_services_config`            | Configuration options for core platform services                                                                                                                                                                                                                                                  | `any` _(see appendix h)_                 | `nil`                |    `yes`     |
| `ingress_node_pool`               | Specifies if a cluster managed ingress node group is required, if `true` the system ingress node group will be given instances. If you're using custom ingress controllers this either needs to be set to `true` or you need to follow the instructions for managing your own ingress node group. | `bool`                                   | `false`              |     `no`     |
| `location`                        | Azure region in which to build resources.                                                                                                                                                                                                                                                         | `string`                                 | `nil`                |    `yes`     |
| `log_analytics_workspace_id`      | ID of an existing Log Analytics Workspace to be used for the Azure Monitor Container Insights add-on. By setting this option, you are agreeing that Azure will deploy and manage a service on the cluster to send metrics and logs to Log Analytics                                               | `string`                                 | `nil`                |     `no`     |
| `network_plugin`                  | Kubernetes Network Plugin (kubenet or azure)                                                                                                                                                                                                                                                      | `string`                                 | `"kubenet"`          |     `no`     |
| `node_pools`                      | Node pool definitions.                                                                                                                                                                                                                                                                            | `list(object())` _(see appendix b)_      | `nil`                |    `yes`     |
| `podnet_cidr`                     | CIDR range for pod IP addresses when using the `kubenet` network plugin.                                                                                                                                                                                                                          | `string`                                 | `"100.65.0.0/16"`    |     `no`     |
| `resource_group_name`             | Name of the Resource Group to deploy the AKS Kubernetes service into, must already exist.                                                                                                                                                                                                         | `string`                                 | `nil`                |    `yes`     |
| `sku_tier`                        | Set cluster control plane SKU tier to either **Free** or **Paid**. The paid tier has a financially-backed uptime SLA, see [documentation](https://docs.microsoft.com/en-us/azure/aks/uptime-sla)                                                                                                  | `string`                                 | `nil`                |    `yes`     |
| `tags`                            | Tags to be applied to cloud resources.                                                                                                                                                                                                                                                            | `map(string)`                            | `{}`                 |     `no`     |
| `virtual_network`                 | Virtual network configuration.                                                                                                                                                                                                                                                                    | `object(map)` _(see appendix d)_         | `nil`                |    `yes`     |

### Appendix A

`azuread_clusterrole_map` object specification.

| **Variable**           | **Description**                                                      | **Type**    | **Default** |
| :--------------------- | :------------------------------------------------------------------- | :---------- | :---------- |
| `cluster_admin_users`  | A map of Azure AD Ids to be assigned full cluster admin permissions. | `string`    | `nil`       |
| `cluster_view_users`   | A map of Azure AD Ids to be assigned full cluster read permissions.  | `string`    | `nil`       |
| `standard_view_users`  | A map of Azure AD Ids to be assigned basic cluster read permissions. | `mapstring` | `nil`       |
| `standard_view_groups` | A map of Azure AD Ids to be assigned basic cluster read permissions. | `string`    | `nil`       |

> see [RBAC documentation](/modules/core-config/modules/rbac/README.md) for more details

### Appendix B

`node_pools` object specification.

| **Variable**          | **Description**                                                                                                                                                                                                              | **Type**                          | **Default** |
| :-------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------- | :---------- |
| `name`                | Node pool name.                                                                                                                                                                                                              | `string`                          | `nil`       |
| `single_vmss`         | `false` creates a single node pool across all zones, `true` creates node pools of the same specification in all zones to support stateful services.                                                                          | `bool`                            | `nil`       |
| `public`              | Set to `true` to assign a public IP to nodes in the pool.                                                                                                                                                                    | `bool`                            | `nil`       |
| `placement_group_key` | If specified the node group will be added to a proximity placement group created for the key in a zone, `single_vmss` must be `false`. The key must be lowercase, alphanumeric, maximum 11 characters, please refer to [documentation](/docs/README.md#proximity-placement-groups) for warnings and considerations. | `bool`                            | `string`    |
| `node_type`           | Type of instance being created in the node group(s).  Append "-win" for Windows node pools (example: "x64-gp-v1-win"). Windows are nodes only supported when network_plugin set to "azure".                                  | `string`                          | `nil`       |
| `node_size`           | Size of instance being created in the node pool(s) using generic sizes and based on the node_type, see the [node type/size matrix](/modules/nodes/matrix.md) for size classes                                                | `string`                          | `nil`       |
| `min_capacity`        | Minimum number of instances the resultant node pool(s) should have.  If `single_vmss` is set to false, this number must be divisible by the number of Availability Zones (3).                                                | `number`                          | `nil`       |
| `max_capacity`        | Maximum number of instances the resultant node pool(s) should have. If `single_vmss` is set to false, this number must be divisible by the number of Availability Zones (3).                                                 | `number`                          | `nil`       |
| `labels`              | Kubernetes node labels to apply to nodes in the pool.                                                                                                                                                                        | `map(string)`                     | `nil`       |
| `taints`              | Kubernetes taints to apply to nodes in the pool.                                                                                                                                                                             | `list(object)` _(see appendix c)_ | `nil`       |
| `tags`                | Additional cloud tags to apply to the node pool.                                                                                                                                                                             | `map(string)`                     | `nil`       |

### Appendix C

`node_pools.taints` object specification.

| **Variable** | **Description**                                                                           | **Type** | **Default** |
| :----------- | :---------------------------------------------------------------------------------------- | :------- | :---------- |
| `key`        | The key of the taint. Maximum length of 63.                                               | `string` | `nil`       |
| `value`      | The value of the taint. Maximum length of 63.                                             | `string` | `nil`       |
| `effect`     | The effect of the taint. Valid values: `NO_SCHEDULE`, `NO_EXECUTE`, `PREFER_NO_SCHEDULE`. | `string` | `nil`       |


### Appendix D

`virtual_network` object specification.

| **Variable**     | **Description**                                        | **Type**                         | **Default** |
| :--------------- | :----------------------------------------------------- | :------------------------------- | :---------- |
| `subnets`        | Map of public and private subnet ids.                  | `object(map)` _(see appendix e)_ | `nil`       |
| `route_table_id` | Route table id attached to public and private subnets. | `string`                         | `nil`       |

### Appendix E

`virtual_network.subnets` object specification.

| **Variable** | **Description**    | **Type**      | **Default** |
| :----------- | :----------------- | :------------ | :---------- |
| `public`     | Public subnet id.  | `object(map)` | `nil`       |
| `private`    | Private subnet id. | `object(map)` | `nil`       |


### Appendix F

`core_services_config` object specification.

| **Variable**                  | **Description**                              | **Type**                 |
| :---------------------------- | :------------------------------------------- | :----------------------- |
| `alertmanager`                | _Alert Manager_ configuration.               | `any` _(see appendix G)_ |
| `cert_manager`                | _Cert Manager_ configuration.                | `any` _(see appendix H)_ |
| `external_dns`                | _External DNS_ configuration.                | `any` _(see appendix I)_ |
| `fluentd`                     | _Fluentd_ configuration.                     | `any` _(see appendix J)_ |
| `grafana`                     | _Grafana_ configuration.                     | `any` _(see appendix K)_ |
| `ingress_internal_core`       | _Ingress_ configuration.                     | `any` _(see appendix L)_ |
| `prometheus`                  | _Prometheus_ configuration.                  | `any` _(see appendix M)_ |
| `monitor-diagnostic-settings` | _Monitor Diagnostic Settings_ configuration. | `any` _(see appendix N)_ |
| `coredns`                     | _Coredns_ configuration.                     | `any` _(see appendix O)_ |


### Appendix G

`alertmanager` object specification.

| **Variable** | **Description**                                                                               | **Type** | **Required** |
| :----------- | :-------------------------------------------------------------------------------------------- | :------- | :----------- |
| `smtp_host`  | SMTP host to send alert emails.                                                               | `string` | **Yes**      |
| `smtp_from`  | SMTP from address for alert emails.                                                           | `string` | **Yes**      |
| `receivers`  | [Receiver configuration](https://prometheus.io/docs/alerting/latest/configuration/#receiver). | `any`    | No           |
| `routes`     | [Route configuration](https://prometheus.io/docs/alerting/latest/configuration/#route).       | `any`    | No           |

### Appendix H

`cert_manager` object specification.

| **Variable**              | **Description**                                                                                                               | **Type**      | **Required** |
| :------------------------ | :---------------------------------------------------------------------------------------------------------------------------- | :------------ | :----------- |
| `dns_zones`               | DNS zones that _Lets Encrypt_ can manage certificates for, must be set up as an _Azure DNS_ public zones in the subscription. | `map(string)` | No           |
| `letsencrypt_environment` | _Lets Encrypt_ environment, supported values `staging` or `production`.                                                       | `string`      | No           |
| `letsencrypt_email`       | Email address for certificate expiry notifications.                                                                           | `string`      | No           |
| `additional_issuers`      | Additional issuers to install into the cluster.                                                                               | `map(any)`    | No           |
| `azure_environment`       | Azure Cloud environment, `AzurePublicCloud` (default) or `AzureUSGovernmentCloud`.                                            | `string  `    | No           |

### Appendix I

`external_dns` object specification.

| **Variable**                  | **Description**                                                                                                              | **Type**       | **Required** |
| :---------------------------- | :--------------------------------------------------------------------------------------------------------------------------- | :------------- | :----------- |
| `azure_environment`           | Azure Cloud environment, `AzurePublicCloud` (default) or `AzureUSGovernmentCloud`.                                           | `string  `     | No           |
| `additional_sources`          | Additional _Kubernetes_ objects to be watched.                                                                               | `list(string)` | No           |
| `public_resource_group_name`  | Name of the Azure Resource Group hosting public DNZ zones, public zones managed by external-dns must be in the same group.   | `string`       | No           |
| `private_resource_group_name` | Name of the Azure Resource Group hosting private DNZ zones, private zones managed by external-dns must be in the same group. | `string`       | No           |
| `public_zones`                | A list of public DNS zones to be managed by external-dns, must be hosted within the resource group input.                    | `list(string)` | No           |
| `private_zones`               | A list of private DNS zones to be managed by external-dns, must be hosted within the resource group input.                   | `list(string)` | No           |

### Appendix J

`fluentd` object specification.

| **Variable**       | **Description**                                                                     | **Type**      | **Required** |
| :----------------- | :---------------------------------------------------------------------------------- | :------------ | :----------- |
| `image_repository` | Custom image repository to use for the Fluentd image, image_tag must also be set.   | `string`      | No           |
| `image_tag`        | Custom image tag to use for the Fluentd image, image_repository must also be set.   | `string`      | No           |
| `additional_env`   | Additional environment variables.                                                   | `list(any)`   | No           |
| `debug`            | If `true` all logs are printed to stdout.                                           | `bool`        | No           |
| `pod_labels`       | Labels to add to fluentd pods, used for pod-identity or cloud storage integrations. | `map(string)` | No           |
| `filters`          | _Fluentd_ filter config split into multiple strings\_.                              | `string`      | No           |
| `routes`           | _Fluentd_ route config split into multiple strings\_.                               | `string`      | No           |
| `outputs`          | _Fluentd_ output config split into multiple strings\_.                              | `string`      | No           |

### Appendix K

`grafana` object specification.

| **Variable**              | **Description**                | **Type**       | **Required** |
| :------------------------ | :----------------------------- | :------------- | :----------- |
| `admin_password`          | Admin password.                | `string`       | No           |
| `additional_data_sources` | Additional data sources.       | `list(any)`    | No           |
| `additional_plugins`      | Additional plugins to install. | `list(string)` | No           |

### Appendix L

`ingress_internal_core` object specification.

| **Variable**       | **Description**                                                                                                  | **Type**       | **Required** |
| :----------------- | :--------------------------------------------------------------------------------------------------------------- | :------------- | :----------- |
| `domain`           | Internal ingress domain.                                                                                         | `string`       | **Yes**      |
| `subdomain_suffix` | Suffix to add to internal ingress subdomains, if not set cluster name will be used.                              | `string`       | No           |
| `lb_source_cidrs`  | Source CIDR ranges accepted by the ingress load balancer, defaults to `10.0.0.0/8` & `100.65.0.0/16` (POD CIDR). | `list(string)` | No           |

### Appendix M

`prometheus` object specification.

| **Variable**   | **Description**                     | **Type**       | **Required** |
| :------------- | :---------------------------------- | :------------- | :----------- |
| `remote_write` | Remote write endpoints for metrics. | `list(string)` | No           |

### Appendix N

`monitor-diagnostic-settings` object specification.

| **Variable**         | **Description**                                                  | **Type** | **Required** |
| :------------------- | :--------------------------------------------------------------- | :------- | :----------- |
| `storage_account_id` | Storage account id to store a secondary copy of diagnostic logs. | `string` | No           |

### Appendix O

`coredns` object specification.

| **Variable**    | **Description**                                                              | **Type**      | **Required** |
| :-------------- | :--------------------------------------------------------------------------- | :------------ | :----------- |
| `forward_zones` | The map of DNS zones and DNS server IP addresses to forward dns requests to. | `map(string)` | No           |

---

## Outputs

| Name                                     | Description |
| ---------------------------------------- | ----------- |
| `aks_cluster_effective_outbound_ips_ids` | n/a         |
| `cluster_id`                             | n/a         |
| `cluster_name`                           | n/a         |
| `kube_config`                            | n/a         |
| `kubelet_identity`                       | n/a         |
| `principal_id`                           | n/a         |
