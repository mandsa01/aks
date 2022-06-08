# Azure AKS Terraform Module Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## Upgrading From Pre v1.0.0-beta.10 Versions

All clusters created with a module version older than `v1.0.0-beta.10` need to be destroyed and re-created with the latest version of the module.

---

<!-- ## [vX.Y.Z] - UNRELEASED
### Added
### Changed
### Updated
### Deprecated
### Removed -->

## [v1.0.0-beta.12] - 2022-06-06

### Added

- Added experimental support to specify the set of control plane log categories via the `workspace_log_categories` & `storage_log_categories` experimental arguments. [@stevehipwell](https://github.com/stevehipwell)
- Added version tag to cluster resource. [@james1miller93](https://github.com/james1miller93)

### Changed

- Fixed indentation on `node-exporter` Prometheus rule. [@prikesh-patel](https://github.com/prikesh-patel)
- Changed the default control plane log categories to use `kube-audit-admin` instead of `kube-audit`. [@stevehipwell](https://github.com/stevehipwell)
- Fixed bug where count cannot be determined until apply when resource group is created and `experimental.oms_agent` is enabled in same workspace. [@james1miller93](https://github.com/james1miller93)

### Updated

- Updated _Kube Prometheus Stack_ chart to [v35.4.2](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-35.4.2). (#455) [@james1miller93](https://github.com/james1miller93)

### Removed

- Removed experimental `kube_audit_object_store_only` variable and replaced it with the new `workspace_log_categories` & `storage_log_categories` experiments. [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.11] - 2022-05-23

### Added

- Added support for [AKS v1.22](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli). [@stevehipwell](https://github.com/stevehipwell)
- Added experimental support for excluding `kube-audit` logs from Log Analytics via the `kube_audit_object_store_only` experimental flag; this should only be used for cost concerns and isn't recommended from a Kubernetes perspective. [@stevehipwell](https://github.com/stevehipwell)

### Updated

- The _AAD Pod Identity_ chart has been upgraded to `4.1.10` (contains [v1.8.9](https://github.com/Azure/aad-pod-identity/releases/tag/v1.8.9) of the aad-pod-identity image). [@james1miller93](https://github.com/james1miller93)
- The _Fluent Bit_ chart has been upgraded to [v0.20.1](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.20.1) (contains _Fluent Bit_ [v1.9.3](https://github.com/fluent/fluent-bit/releases/tag/v1.9.3)). [@prikesh-patel](https://github.com/prikesh-patel)
- The _Kube Prometheus Stack_ chart has been upgraded to [v35.2.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-35.2.0). [@prikesh-patel](https://github.com/prikesh-patel)
- The _Ingress Nginx_ chart has been upgraded to [v4.1.1](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.1.1). [@prikesh-patel](https://github.com/prikesh-patel)

## [v1.0.0-beta.10] - 2022-05-09

> **Important**
> This release is a significant breaking change and intended to be the last in the `beta` series with a stable `rc` being planned for the next release.

### Added

- Added experimental support for [AKS v1.22](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli). [@stevehipwell](https://github.com/stevehipwell)
- Support for `cpu` node types. [@stevehipwell](https://github.com/stevehipwell)
- Support for `gp`, `gpd`, `mem` & `memd` `v2` node types. [@stevehipwell](https://github.com/stevehipwell)
- Node type & size documentation has been added to the module README. [@stevehipwell](https://github.com/stevehipwell)

### Changed

- The system node pools can now be upgraded automatically by the module. [@stevehipwell](https://github.com/stevehipwell)
- The node image versions should be automatically upgraded. [@stevehipwell](https://github.com/stevehipwell)
- The AKS cluster now only uses a single subnet with isolation expected to be clontrolled by node taints and network restrictions provided by `NetworkPolicies`. [@stevehipwell](https://github.com/stevehipwell)
- Control plane logging has been turned on for all types. [@stevehipwell](https://github.com/stevehipwell)
- Cert manager now has multiple ACME issuers installed so you can use the right one for each certificate. [@stevehipwell](https://github.com/stevehipwell)
- The internal ingress certificate is now created in the ingress namespace. [@stevehipwell](https://github.com/stevehipwell)
- Module variables have been changed, check the README for more details. [@stevehipwell](https://github.com/stevehipwell)
- Kubernetes based providers must be configured to use the `exec` plugin pattern. [@stevehipwell](https://github.com/stevehipwell)
- The module architecture has been flattened and simplified. [@stevehipwell](https://github.com/stevehipwell)
- This module can be used in a new Terraform workspace first apply as no `data` lookups are used that aren't known at plan. [@stevehipwell](https://github.com/stevehipwell)
- Unsupported features, Windows nodes and OMS Agent, have been moved behind the `experimental` variable. [@stevehipwell](https://github.com/stevehipwell)
- Terraform dependency graph has been updated to make sure that create and destroy steps happen in the correct order. [@stevehipwell](https://github.com/stevehipwell)

### Updated

- The `azurerm` Terraform provider has been updated to `v3`, this means all modules and resources in your workspace will need updating to support this. [@stevehipwell](https://github.com/stevehipwell)
- All core services have been aligned to the versions used in the EKS module. [@stevehipwell](https://github.com/stevehipwell)

### Removed

- The community module dependency has been removed. [@stevehipwell](https://github.com/stevehipwell)
- The module no longer exposes Kubernetes credentials, you need to use `az` and `kubelogin` to connect to the cluster. [@stevehipwell](https://github.com/stevehipwell)

## [v1.0.0-beta.9] - 2022-03-14

### Updated

- `fluent-bit` upgrade chart to [0.19.20](https://github.com/fluent/helm-charts/releases/tag/fluent-bit-0.19.20) ([#353](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/353)) [@james1miller93](https://github.com/james1miller93)
- `ingress-nginx` upgrade chart to [4.0.18](https://github.com/kubernetes/ingress-nginx/releases/tag/helm-chart-4.0.18) ([#358](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/358)) [@james1miller93](https://github.com/james1miller93)
- `kube-prometheus-stack` upgrade chart to [33.2.0](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-33.2.0) ([#354](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/354)) [@james1miller93](https://github.com/james1miller93)

## [v1.0.0-beta.8] - 2022-02-28

### Added

- `module` - added **sku_tier** variable to set [control plane SLA](https://docs.microsoft.com/en-us/azure/aks/uptime-sla) level [@dutsmiller](url) [@jamurtag](url)
- **BREAKING** - Added support for setting node pool [proximity placement group](https://docs.microsoft.com/en-us/azure/aks/reduce-latency-ppg#:~:text=A%20proximity%20placement%20group%20is,and%20tasks%20that%20complete%20quickly.) via the `placement_group_key` variable. [@stevehipwell](https://github.com/stevehipwell)

### Changed

- `aad-pod-identity` - updated chart to 4.1.8 ([#329](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/329)) [@james1miller93](https://github.com/james1miller93)
- `cert-manager` - replaced custom roles with builtin roles ([#236](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/236)) [@james1miller93](https://github.com/james1miller93)
- `cert-manager` - updated chart to 1.7.1 ([#330](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/330)) [@james1miller93](https://github.com/james1miller93)
- `external-dns` - replaced custom roles with builtin roles ([#236](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/236)) [@james1miller93](https://github.com/james1miller93)
- `fluent-bit` - updated chart to 0.19.19 ([#331](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/331)) [@james1miller93](https://github.com/james1miller93)
- `fluentd` - updated chart to 2.6.9 ([#332](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/332)) [@james1miller93](https://github.com/james1miller93)
- `ingress-nginx` - updated chart to 4.0.17 ([#334](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/3349)) [@james1miller93](https://github.com/james1miller93)
- `kube-prometheus-stack` - updated chart to [32.2.1](https://github.com/prometheus-community/helm-charts/releases/tag/kube-prometheus-stack-32.2.1) and CRDs to 0.54.0 (includes Grafana [v8.3.5](https://github.com/grafana/grafana/releases/tag/v8.3.5)) [@james1miller93](https://github.com/james1miller93)
- `provider-azurerm` - restrict azurerm terraform provider to v2 [prikesh-patel](https://github.com/prikesh-patel)
- Updated documentation. [@stevehipwell](https://github.com/stevehipwell)
- Update version of upstream AKS module. [@dutsmiller](url)

> **IMPORTANT** - As part of the `cert-manager` upgrade, all of the cert manager crds need to be patched manually `prior` to upgrading to the `v1.0.0-beta.8` tag. An [issue](https://github.com/cert-manager/cert-manager/issues/4831) has been raised against the upstream repository to track this. Please see [UPGRADE.md](/UPGRADE.md#from-v100-beta7-to-v100-beta8) for details.
> **IMPORTANT** - The _Cert Manager_ API versions `v1alpha2`, `v1alpha3`, and `v1beta1` have been removed. All _Cert Manager_ custom resources must only use `v1` before upgrading to this release. All certificates are already stored as `v1`, after this release you can only access deprecated API resources through the _Cert Manager_ API.

## [v1.0.0-beta.7] - 2022-02-08

### Added

- `documentation` - added [documentation](/UPGRADE.md) for module & AKS version upgrades [@sossickd](url)

### Changed

- `aad-pod-identity` - updated chart to 4.1.7 [@sossickd](url)
- `cert-manager` - added toleration and node selector for startupapicheck [@sossickd](url)
- `cluster-autoscaler` - disabled autoscaling for node pools when min/max settings are the same [@dutsmiller](url)
- `ingress_internal_core` updated chart to 4.0.16 [@sossickd](url)
- `ingress_internal_core` replace dashboard with Grafana dashboard [14314](https://grafana.com/grafana/dashboards/14314) [@sossickd](url)
- `kubectl provider` - enabled server-side-apply aad-pod-identity [@sossickd](url)
- `kube-prometheus-stack` - updated chart to 30.1.0 and CRDs to 0.53.1 (see **IMPORTANT** note below) [@sossickd](url)
- `kube-prometheus-stack` - added resource limits for prometheusConfigReloader [@sossickd](url)
- `kube-prometheus-stack` - enabled update strategy for node-exporter daemonset [@sossickd](url)
- `kube-prometheus-stack` - enabled service monitor for kube-state-metrics, node-exporter [@sossickd](url)
- `kubectl provider` - enabled server-side-apply aad-pod-identity, kube-promethues-stack, ingress_internal_core, rbac, identity [@sossickd](url)
- `grafana` - updated container image to 8.3.3, removed temporary fix to mitigate [CVE-2021-43798](https://nvd.nist.gov/vuln/detail/CVE-2021-43798) & [CVE-2021-43813](https://grafana.com/blog/2021/12/10/grafana-8.3.2-and-7.5.12-released-with-moderate-severity-security-fix/) [@sossickd](url)
- `module` - Kubernetes patch versions updated for 1.20 and 1.21 (see **IMPORTANT** note below) [@dutsmiller](url)
- `storage-classes` - migrate storage classes created by the module to [CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers) for 1.21.x clusters (see IMPORTANT note below)[@sossickd](url)

### Removed

- `module` - dropped support for Kubernetes version 1.19 (see **IMPORTANT** note below) [@dutsmiller](url)

> **IMPORTANT** - Dropped support for Kubernetes version 1.19, patch versions updated for 1.20 and 1.21. This will instigate a cluster upgrade, refer to [UPGRADE.md](/UPGRADE.md) for module and Kubernetes version upgrade instructions and troubleshooting steps.
> **IMPORTANT** - Due to an upgrade of the `kube-state-metrics` chart as part of the `kube-prometheus-stack` upgrade, removal of its deployment needs to done manually `prior` to upgrading to the `v1.0.0-beta.7` tag. Please see [UPGRADE.md](/UPGRADE.md#from-v100-beta6-to-v100-beta7) for details.
> **IMPORTANT** - The following storage classes have been migrated to CSI drivers in the 1.21 release - `azure-disk-standard-ssd-retain`, `azure-disk-premium-ssd-retain`, `azure-disk-standard-ssd-delete` and `azure-disk-premium-ssd-delete`. If you created custom storage classes using the kubernetes.io/azure-disk or kubernetes.io/azure-file provisioners they will need to be [migrated to CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers#migrating-custom-in-tree-storage-classes-to-csi). Please use `v1.0.0-beta.7` or above to create new 1.21 clusters.

## [v1.0.0-beta.6] - 2022-01-14

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- `coredns` - added corends module to support on-premise name resolution [@sossickd](url)
- `module` - added required core_services_config parameters to examples [@sossickd](url)

### Changed

- `fluent-bit` - updated chart to 0.19.16 [@sossickd](url)
- `fluent-bit` - revert cri multi-line parser back to the standard parser until upstream [issue](https://github.com/fluent/fluent-bit/issues/4377) has been fixed [@sossickd](url)
- `fluentd` - updated chart to 2.6.7 [@sossickd](url)
- `fluentd` - fix image tag and repository override [@sossickd](url)
- `external-dns` - updated chart to 1.7.1 [@sossickd](url)
- `local_storage` - added dependency on kube-prometheus-stack CRDs [@sossickd](url)
- `module` - removed providers from module and version constraints from sub-modules (see IMPORTANT note below) [@sossickd](url)
- `cert-manager` - updated chart and CRDs to 1.6.1 [@sossickd](url)
- `kubectl provider` - enabled server-side-apply for fluent-bit, cert-manager [@sossickd](url)

> **IMPORTANT** - Providers have now been removed from the module which requires changes to the Terraform workspace. All providers **must** be declared and configuration for the `kubernetes`, `kubectl` & `helm` providers **must** be set. See [examples](/examples) for valid configuration and review the [CHANGELOG](/CHANGELOG.md) on each release.

## [v1.0.0-beta.5] - 2021-12-14

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- `CSI` - added local volume provisioner for local nvme & ssd disks [@dutsmiller](url)
- `Diagnostics` - AKS control plane logs written to log analytics workspace in cluster resource group [@sossickd](url)

### Changed

- `API` - added version field to node_types (see **IMPORTANT** note below) [@dutsmiller](url)
- `AzureUSGovernmentCloud` - added `azure_environment` variable to set cloud environment [@dutsmiller](url)
- `AzureUSGovernmentCloud` - added support for AAD member users [@dutsmiller](url) [@jamurtag](url)
- `AzureUSGovernmentCloud` - added support in external-dns & cert-manager [@sossickd](url)
- `Documentation` - clarification of Windows node pool support [@jamurtag](url)
- `external-dns` - changed logging format to json [@sossickd](url)
- `fluent-bit` - updated chart to 0.19.5 [@sossickd](url)
- `fluent-bit` - added update strategy & [multiline](https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/multiline-parsing) support [@sossickd](url)
- `fluentd` - updated chart to 2.6.5 [@sossickd](url)
- `fluentd` - changed filter_config, route_config & output_config variables to filters, routes & outputs [@sossickd](url)
- `fluentd` - support for custom image repository and tag via image_repository & image_tag variables [@sossickd](url)
- `fluentd` - add extra fields to logs including cluster_name, subscription_id and location [@sossickd](url)
- `kube-prometheus-stack` - updated chart to 19.3.0 & CRDs to 0.50.0 [@sossickd](url)
- `kubectl provider` - updated version to 1.12.1 [@dutsmiller](url)
- `kubectl provider` - enabled server-side-apply for fluentd, kube-prometheus-stack, external-dns [@sossickd](url)
- `Grafana` - updated container image to 8.3.2 to mitigate [CVE-2021-43798](https://nvd.nist.gov/vuln/detail/CVE-2021-43798) & [CVE-2021-43813](https://grafana.com/blog/2021/12/10/grafana-8.3.2-and-7.5.12-released-with-moderate-severity-security-fix/) [@jamurtag](url)
- `Grafana` - managed identity support & Azure role assignment for access to managed resources [@jamurtag](url)
- `Grafana` - added grafana_identity output for custom Azure role assignments [@jamurtag](url)
- `Grafana` - added Azure Monitor data source for access to Azure resources [@sossickd](url)
- `Grafana` - added dashboard to view control plane diagnostics logs [@sossickd](url)
- `Tags` - added cloud tags to all provisioned resources [@prikesh-patel](url)
- `VM Types` - added gpd, mem, memd, and stor vm types (see [matrix](./modules/nodes/matrix.md) for node types) [@dutsmiller](url)

> **IMPORTANT** - Existing node types must have "-v1" appended to be compatible with beta.5.  Example:  The beta.4 node type of "x64-gp" would need to be changed to "x64-gp-v1" to maintain compatibility .  All future node types will be versioned.  See [matrix](./modules/nodes/matrix.md) for node types and details.
> **IMPORTANT** - If you are currently using `filter_config`, `route_config` or `output_config` in the fluentd section of the core_services_config these will need to be renamed accordingly.

## [v1.0.0-beta.4] - 2021-11-02

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Changed

- ingress-nginx chart updated to version 4.0.6 [@jamurtag](url)
- aad-pod-identity chart updated to version 4.1.5 [@jamurtag](url)
- aad-pod-identity requests and limits lowered for both NMI and MIC pods [@jamurtag](url)
- Default to AzurePublicCloud in cert-manager config [@jamurtag](url)
- Minor formatting change to cert-manager cluster-issuer config [@sossickd](url)
- Reduced ingress-nginx cpu / memory requests to 50m / 128MB (from 200m / 256MB) [@jamurtag](url)
- Changed prometheus-operator memory requests / limits to 128MB / 512 MB (from 256MB / 256MB) [@jamurtag](url)
- Changed kube-state-metrics memory requests / limits to 128MB / 1024MB (from 256MB / 512MB) [@jamurtag](url)
- Added documentation for system node pool service resource tracking and reporting [@jamurtag](url)
- Explicitly set Azure Policy and Dashboard add-on status to avoid noise in plans [@dutsmiller](url)
- Improve Virtual Network documentation [@dutsmiller](url)
- Explicitly set max_pods for kubenet/AzureCNI [@dutsmiller](url)
- Set `allowSnippetAnnotations` to `false` on ingress-nginx chart to mitigate [security vulnerability](https://www.armosec.io/blog/new-kubernetes-high-severity-vulnerability-alert-cve-2021-25742) [@prikesh-patel](url)
- Updated support policy regarding Windows node pools and nested Terraform modules [@jamurtag](url)

## [v1.0.0-beta.3] - 2021-09-29

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- AzureUSGovernmentCloud support in cert-manager [@jhisc](url)
- Helm chart for external-dns to create dns records in Azure private dns-zones [@sossickd](url)
- Grafana dashboard for external-dns [@sossickd](url)
- Grafana dashboard for ingress_internal_core [@sossickd](url)

### Changed

- Helm chart renamed from external-dns to external-dns-public [@sossickd](url)
- External dns helm chart moved from [bitnami external-dns](https://github.com/bitnami/charts/tree/master/bitnami/external-dns) to [kubernetes-sigs external-dns](https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns) [@sossickd](url)
- Updated ingress_internal_core to helm version 4.0.2 [@sossickd](url)
- Updated kubernetes provder to v2.5 [@fabiendelpierre](url)

> **IMPORTANT** - Please change the core_services_config input for external_dns.

## [v1.0.0-beta.2] - 2021-09-10

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Cluster ID output [@dutsmiller](url)

### Changed

- Set ingress-nginx & PrometheusOperator adminissionWebhook to run on system nodepool [@jamurtag](url)
- Output changed:  aks_cluster_name -> cluster_name [@dutsmiller](url)

## [v1.0.0-beta.1] - 2021-08-20

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Azure Log Analytics support [@appkins](url)
- Ingress node pool [@dutsmiller](url)

### Changed

- Fix default-ssl-certificate in ingress_internal_core module [@sossickd](url)
- User guide updates [@jamurtag](url)

## [v0.12.0] - 2021-08-11

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Support for k8s 1.21 [@dutsmiller](url)

### Changed

- Node pool variable changes [@dutsmiller](url)
- Change pod_cidr variable to podnet_cidr [@dutsmiller](url)
- Change core_services_config ingress_core_internal to ingress_internal_core [@dutsmiller](url)
- Change multi-vmss node pool capacity format [@dutsmiller](url)

### Removed

- Remove configmaps, secrets and namespaces variables [@dutsmiller](url)
- Remove assignment of public IPs for nodes in public subnet [@dutsmiller](url)

## [v0.11.0] - 2021-07-27

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Calico network policy support [@jamurtag](url)
- AKS API firewall support [@dutsmiller](url)

### Changed

- Update README and simplify core_services_config variable input [@jamurtag](url)
- Update upstream AKS module version [@dutsmiller](url)
- Change name of UAI for AKS [@dutsmiller](url)
- Force host encryption to true [@dutsmiller](url)

### Removed

- Remove additional_priority_classes and additional_storage_classes api options [@jamurtag](url)
- Remove autodoc from repo [@dutsmiller](url)

## [v0.10.0] - 2021-07-19

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Changed

- Tolerate stateful services on system nodepools [@jamurtag](url)
- Rename config variable to core_services_config [@jamurtag](url)

## [v0.9.0] - 2021-07-14

> **IMPORTANT** - This pre-release isn't guaranteed to be stable and should not be used in production.

### Added

- Added wildcard certificate for core services [@sossickd](url)
- Documentation for cert-manager, external-dns, priority classes and storage claasses [@fabiendelpierre](url)

### Changed

- Node pool format to match EKS [@dutsmiller](url)
