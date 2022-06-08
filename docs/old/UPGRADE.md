# AKS Pre-Release Upgrade Documentation

- [AKS Pre-Release Upgrade Documentation](#aks-pre-release-upgrade-documentation)
  - [Recommendations](#recommendations)
  - [Upgrading Module Versions](#upgrading-module-versions)
    - [From `v1.0.0-beta.8` to `v1.0.0-beta.9`](#from-v100-beta8-to-v100-beta9)
    - [From `v1.0.0-beta.7` to `v1.0.0-beta.8`](#from-v100-beta7-to-v100-beta8)
    - [From `v1.0.0-beta.6` to `v1.0.0-beta.7`](#from-v100-beta6-to-v100-beta7)
    - [From `v1.0.0-beta.5` to `v1.0.0-beta.6`](#from-v100-beta5-to-v100-beta6)
    - [From `v1.0.0-beta.4` to `v1.0.0-beta.5`](#from-v100-beta4-to-v100-beta5)
    - [From `v1.0.0-beta.3` to `v1.0.0-beta.4`](#from-v100-beta3-to-v100-beta4)
    - [From `v1.0.0-beta.2` to `v1.0.0-beta.3`](#from-v100-beta2-to-v100-beta3)
    - [From `v1.0.0-beta.1` to `v1.0.0-beta.2`](#from-v100-beta1-to-v100-beta2)
  - [Upgrading Kubernetes Minor Versions](#upgrading-kubernetes-minor-versions)
    - [From `1.20.x` to `1.21.x`](#from-120x-to-121x)
    - [From `1.19.x` to `1.20.x`](#from-119x-to-120x)
  - [Cluster Health Checks](#cluster-health-checks)
    - [PodDisruptionBudgets (PDB)](#poddisruptionbudgets-pdb)
  - [Deprecated API Migration Guide](#deprecated-api-migration-guide)
  - [Troubleshooting](#troubleshooting)
    - [AKS Node Pool Provisioning State Failed](#aks-node-pool-provisioning-state-failed)
    - [Terraform Plan Failed](#terraform-plan-failed)
    - [Terraform Apply Failed](#terraform-apply-failed)

<br>

## Recommendations

Perform the upgrade on AKS clusters in lower environments **BEFORE** upgrading production clusters. Lower environments must mirror workloads in production environments to mitigate unforeseen issues. Ensure monitoring is in place to alert on outages.

To speed up the process when upgrading [module versions](#upgrading-module-versions) or upgrading [Kubernetes minor versions](#upgrading-kubernetes-minor-versions) all steps should be completed **PRIOR** to the upgrade. If missed these steps can be completed retrospectively by performing a re-run of the Terraform plan or apply stages.

Ensure Terraform pipelines have a sufficient timeout window, 2 hours is recommended.

## Upgrading Module Versions

Below is a list of steps that need to be taken when upgrading from one module version to the next. We **DO NOT** support skipping versions and expect that each upgrade is completed independently before running the next one.

Some module upgrades will initiate a Kubernetes patch update; this is required as AKS [frequently drops support](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli) for Kubernetes patch versions.

This upgrade process usually takes less than an hour but can take significantly longer and we recommend allowing for 2 hours. If you're using GitLab to deploy AKS via this Terraform module you must set a CI [timeout](https://docs.gitlab.com/ee/ci/pipelines/settings.html) that is sufficient to complete the upgrade process; we recommend `2` hours.

### From `v1.0.0-beta.8` to `v1.0.0-beta.9`

This release includes no breaking changes to the exposed api. Operators can upgrade without manual intervention.

### From `v1.0.0-beta.7` to `v1.0.0-beta.8`

It is required to set the `sku_tier` variable to either **Free** or **Paid**.

It is required to set the `placement_group_key` within `node_pools` to either "" or a key value.

<br/>

`Manual steps to update Kubernetes resources`

> **IMPORTANT** - All commands needs to run by a cluster operator with permissions to delete resources.

<details>
<summary markdown="span">Explanation for the next step</summary>
<br/>

`cert-manager` - The `kubectl_manifest` terraform resource for applying CRDs has `server-side-apply` enabled. The managed fields on the crd objects cause terraform to error when updating these resources and they must be patched before upgrading.

</details>
<br/>

`cert-manager`

```bash
for crd_name in certificaterequests.cert-manager.io certificates.cert-manager.io challenges.acme.cert-manager.io clusterissuers.cert-manager.io issuers.cert-manager.io orders.acme.cert-manager.io; do
  manager_index="$(kubectl get crd "${crd_name}" --show-managed-fields --output json | jq -r '.metadata.managedFields | map(.manager == "cainjector") | index(true)')"
  kubectl patch crd "${crd_name}" --type=json -p="[{\"op\": \"remove\", \"path\": \"/metadata/managedFields/${manager_index}\"}]"
done
```

### From `v1.0.0-beta.6` to `v1.0.0-beta.7`

> **IMPORTANT** - Updating to this module version will instigate a Kubernetes patch version upgrade. Please read the [Cluster Health Checks](#cluster-health-checks) section prior to updating.

A GitHub [issue](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/305) has been created on the `terraform-azurerm-aks` project to track any problems caused by the Kubernetes patch upgrade. Even though this upgrade path has been tested there may be unforeseen permutations. If you experience a problem that was not remediated by the steps outlined in this guide please add a comment with a detailed description of your experience.

> **IMPORTANT** - To speed up the process complete all steps `prior` to a module version upgrade. If you miss these steps they can be completed retrospectively. This requires you to re-run the Terraform apply stage.

`module version upgrade instigates a Kubernetes patch upgrade`: YES

`Manual steps to delete Kubernetes resources`

> **IMPORTANT** - All commands needs to run by a cluster operator with permissions to delete resources.

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`aad-pod-identity` - The `kubectl_manifest` terraform resource for applying CRDs has `server-side-apply` enabled. This can cause a conflict with HashiCorp using `apiextensions.k8s.io/v1`.

</details>
<br />

`aad-pod-identity`

```console
kubectl delete crd azureassignedidentities.aadpodidentity.k8s.io 
kubectl delete crd azureidentities.aadpodidentity.k8s.io 
kubectl delete crd azureidentitybindings.aadpodidentity.k8s.io 
kubectl delete crd azurepodidentityexceptions.aadpodidentity.k8s.io
```

> **IMPORTANT** - this will remove all custom resources of these types, if user workloads created or consumed AAD Pod Identities the Kubernetes custom resources will need to be recreated

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`kube-prometheus-stack` - The `kubectl_manifest` terraform resource for applying CRDs has `server-side-apply` enabled. This can cause a conflict with HashiCorp using `apiextensions.k8s.io/v1`.

</details>
<br />

`kube-prometheus-stack`

```console
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

> **IMPORTANT** - this will remove all custom resources of these types, if user workloads created any of these the Kubernetes custom resources will need to be recreated

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`kube-prometheus-stack` - This step is required due to an upgrade of the `kube-state-metrics` deployment.

</details>
<br />

`kube-state-metrics`

```console
kubectl delete deployment kube-prometheus-stack-kube-state-metrics -n monitoring
```

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`ingress_internal_core` - Ingress Grafana dashboard configmap is being handled by a different `kubectl_manifest`. This causes a known `cycle` error as the resource get destroyed on the Terraform apply phase.

</details>
<br />

`ingress_internal_core`

> **IMPORTANT** - This next step is only required if upgrading from module version `v1.0.0-beta.3` and above.

```console
kubectl delete configmap dashboard-ingress-core-internal -n ingress-core-internal
```

> **IMPORTANT** - This next step is only required if on or upgrading to Kubernetes `1.21.x`

`storage-classes`

The change to the storage classes to use CSI drivers causes the Kubernetes resources to be replaced during a Terraform apply, this causes a known `cycle` error. Delete existing platform storage classes before upgrading - this does not impact existing volumes.

```console
kubectl delete storageclass azure-disk-premium-ssd-delete 
kubectl delete storageclass azure-disk-premium-ssd-retain 
kubectl delete storageclass azure-disk-standard-ssd-delete 
kubectl delete storageclass azure-disk-standard-ssd-retain
```

> **IMPORTANT** - if cluster operators created custom storage classes using the kubernetes.io/azure-disk or kubernetes.io/azure-file provisioners they will also need to be [migrated to CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers#migrating-custom-in-tree-storage-classes-to-csi).

<br/>

`DEPRECATION WARNINGS`

`Alertmanager` The helm chart `kube-prometheus-stack` helm chart upgrade to `30.1.0` includes `Alertmanager` version `0.23`. Since this upgrade deprecated syntax warning appear in the kube-prometheus-stack-operator pod logs. If you have created your own custom routes this is advanced warning and maybe a good idea to start considering testing the new [matchers](https://prometheus.io/docs/alerting/latest/configuration/#route) configuration.

```console
kubectl logs kube-prometheus-stack-operator-76d7dc6bd-v89j6 -n monitoring

level=warn ts=2022-01-22T08:31:55.923186487Z caller=amcfg.go:1326 component=alertmanageroperator alertmanager=kube-prometheus-stack-alertmanager namespace=monitoring receiver=alerts msg="'matchers' field is using a deprecated syntax which will be removed in future versions" match="unsupported value type" match_re="unsupported value type"
```

### From `v1.0.0-beta.5` to `v1.0.0-beta.6`

> **IMPORTANT** - To speed up the process complete all steps `prior` to a module version upgrade. If you miss these steps they can be completed retrospectively. This requires you to re-run the Terraform apply stage.

`module version upgrade instigates a Kubernetes patch upgrade`: NO

`Manual steps to delete Kubernetes resources`

> **IMPORTANT** - All commands needs to run by a cluster operator with permissions to delete resources.

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`cert-manager` - The `kubectl_manifest` terraform resource for applying CRDs has `server-side-apply` enabled. This can cause a conflict with HashiCorp using `apiextensions.k8s.io/v1`.

</details>
<br />

`cert-manager`

```console
kubectl delete crd certificaterequests.cert-manager.io 
kubectl delete crd certificates.cert-manager.io 
kubectl delete crd challenges.acme.cert-manager.io 
kubectl delete crd clusterissuers.cert-manager.io 
kubectl delete crd issuers.cert-manager.io 
kubectl delete crd orders.acme.cert-manager.io
```

`Manual steps required to the Terraform workspace`

`module` - Providers have now been removed from the module which requires changes to the Terraform workspace. All providers **must** be declared and configuration for the `kubernetes`, `kubectl` & `helm` providers **must** be set. See [examples](/examples) for valid configuration.

### From `v1.0.0-beta.4` to `v1.0.0-beta.5`

> **IMPORTANT** - To speed up the process complete all steps `prior` to a module version upgrade. If you miss these steps they can be completed retrospectively. This requires you to re-run the Terraform apply stage.

`module version upgrade instigates a Kubernetes patch upgrade`: NO

`Manual steps required to the Terraform workspace`

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`nodepool` - Existing node types must have "-v1" appended to be compatible with `v1.0.0-beta.5`.  Example:  The `v1.0.0-beta.4` node type of `x64-gp` would need to be changed to `x64-gp-v1` to maintain compatibility.  All future node types will be versioned.  See [matrix](./modules/nodes/matrix.md) for node types and details.

</details>
<br />

`nodepool`

```terraform
module "aks" {

  node_pools = [
    {
      name         = "wnp1" # windows worker node pool 1
      node_type    = "x64-gp-v1-win"
    },
    {
      name         = "inp1" # linux ingress node 1
      node_type    = "x64-gp-v1"
    }
  ]
```

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`fluentd` - Changed `filter_config`, `route_config` and `output_config` variables to `filters`, `routes` and `outputs`. If you are currently using `filter_config`, `route_config` or `output_config` in the fluentd section of the core_services_config these will need to be renamed accordingly.

</details>
<br />

`fluentd`

```terraform
module "aks" {
  ...
  core_services_config = {
    fluentd = {
      outputs = <<-EOT
        <label @DEFAULT>
          <match kube.var.log.containers.example-**.log>
            @type elasticsearch
            ....
        </label>
      EOT
    }
    ...
  }
}
```

### From `v1.0.0-beta.3` to `v1.0.0-beta.4`

No additional action required.

### From `v1.0.0-beta.2` to `v1.0.0-beta.3`

> **IMPORTANT** - To speed up the process complete the next step `prior` to a module version upgrade. If you miss these steps they can be completed retrospectively. This requires you to re-run the Terraform apply stage.

`module version upgrade instigates a Kubernetes patch upgrade`: NO

`Manual steps required to the Terraform workspace`

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`external-dns` - Due to changes to `external-dns` it fits the criteria to return [Provider configuration not present](https://support.hashicorp.com/hc/en-us/articles/1500000332721-Error-Provider-configuration-not-present) errors.
</details>
<br />

> **IMPORTANT** - To speed up the process complete the next step `prior` to a module version upgrade. If you miss these steps they can be completed retrospectively. This requires you to re-run the Terraform plan stage.

If you do not complete this step `prior` to the module version upgrade you will receive the following error.

```console
 Error: Provider configuration not present
 ....
 module.aks.module.core-config.module.external_dns.helm_release.main
 (orphan) its original provider configuration at
 module.aks.provider["registry.terraform.io/hashicorp/helm"] is required,
 but it has been removed.
 ```

To resolve the issue remove the orphaned resources from the Terraform state file.

> **IMPORTANT** - Change the name in each of the `terraform state rm` commands from `module.example` to `module.<your-module-name>` otherwise you will receive an error.

```console
terraform state rm 'module.example.module.core-config.module.external_dns.module.identity.kubectl_manifest.identity'
terraform state rm 'module.example.module.core-config.module.external_dns.module.identity.kubectl_manifest.identity_binding'
terraform state rm 'module.example.module.core-config.module.external_dns.helm_release.main'
```

<details>
<summary markdown="span">Explanation for the next step</summary>
<br />

`external-dns` - Changed `resource_group_name` and `zones` variables to `private_resource_group_name` and `private_zones `. If you are currently using `resource_group_name` and `zones` in the external-dns section of the core_services_config these will need to be renamed accordingly.

</details>
<br />

`external-dns`

```terraform
module "aks" {

  core_services_config = {
    external_dns = {
      private_resource_group_name = "azure-resource-group-name"
      private_zones               = ["staging.app.lnrsg.io", "dev.app.lnrsg.io"]
    }
  }
}
```

### From `v1.0.0-beta.1` to `v1.0.0-beta.2`

No additional action required.

---

## Upgrading Kubernetes Minor Versions

> **IMPORTANT** - Please reference the [Deprecated API Migration Guide](#deprecated-api-migration-guide) and [Cluster Health Checks](#cluster-health-checks) prior to starting an upgrade.

When you upgrade an AKS cluster's Kubernetes minor version you can only move up one minor version at a time; for example, upgrades between `1.19.x` -> `1.20.x` or `1.20.x` -> `1.21.x` are allowed, however `1.19.x` -> `1.21.x` is not allowed.

Below is a list of steps that need to be taken when upgrading from one minor version of Kubernetes to the next. For more information on upgrading an AKS cluster please visit the official [Microsoft documentation](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster).

This upgrade process usually takes less than an hour but can take significantly longer and we recommend allowing for 2 hours. If you're using GitLab to deploy AKS via this Terraform module you must set a CI [timeout](https://docs.gitlab.com/ee/ci/pipelines/settings.html) that is sufficient to complete the upgrade process; we recommend `2` hours.

To upgrade the AKS Kubernetes minor version change the `cluster_version` module input to the next version.

<br/>

`Manual steps to delete Kubernetes resources`

> **IMPORTANT** - To speed up the process complete all steps `prior` to a module version upgrade. If you miss these steps they can be completed retrospectively. This requires you to re-run the Terraform apply stage.

> **IMPORTANT** - All commands needs to run by a cluster operator with permissions to delete resources.

<br/>

### From `1.20.x` to `1.21.x`

`storage-class` - The change to the storage classes to use CSI drivers causes the Kubernetes resources to be replaced during a Terraform apply, this causes a known `cycle` error.

Delete existing platform storage classes before upgrading - this does not impact existing volumes.

```console
kubectl delete storageclass azure-disk-premium-ssd-delete 
kubectl delete storageclass azure-disk-premium-ssd-retain 
kubectl delete storageclass azure-disk-standard-ssd-delete 
kubectl delete storageclass azure-disk-standard-ssd-retain
```

> **IMPORTANT** - if cluster operators created custom storage classes using the kubernetes.io/azure-disk or kubernetes.io/azure-file provisioners they will also need to be [migrated to CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers#migrating-custom-in-tree-storage-classes-to-csi).

<br/>

### From `1.19.x` to `1.20.x`

No additional action required.

<br/>

---

## Cluster Health Checks

It is important to carry out cluster health checks prior to completing an upgrade.

### PodDisruptionBudgets (PDB)

It is important to understand PodDisruptionBudgets (PDB) as they can cause a cluster upgrade to fail.

 A PodDisruptionBudget (PDB) is an indicator of the number of disruptions that can be tolerated at a given time for a class of pods (a budget of faults). Whenever a disruption to the pods in a service is calculated to cause the service to drop below the budget, the operation is paused until it can maintain the budget.

 For more information see the Official Kubernetes [documentation](https://kubernetes.io/docs/tasks/run-application/configure-pdb/).

 Lets take `fluentd` for example which is part of the logging service included in the core config.

 `fluentd` is a `statefulset` with replica count of `3`

 ```console
 kubectl get statefulsets -n logging

NAME      READY   AGE
fluentd   3/3     12h
```

 `fluentd` is also configured with PodDisruptionBudget (PDB) with maxUnavailable setting of `1`

 ```console
 kubectl get pdb -n logging
NAME      MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
fluentd   N/A             1                 1                     12h
```

Now in this scenario `0` of the `3` fluentd pods are available. This would cause a cluster upgrade to fail.

 ```console
 kubectl get statefulsets -n logging

NAME      READY   AGE
fluentd   0/3     12h
```

To resolve the issue find the cause as to why `0` of the `3` fluentd pods are available and fix the issue prior to a cluster upgrade. If the pods are in a `Pending` of `Error` state you can use the following commands to troubleshoot.

```console
kubectl describe pod fluentd-0 -n logging

kubectl logs fluentd-0 -n logging
```

---

## Deprecated API Migration Guide

> **IMPORTANT** - Please share this information with any team developing their own helm charts or creating Kubernetes manifests.

As the Kubernetes API evolves, APIs are periodically reorganized or upgraded. When APIs evolve, the old API is deprecated and eventually removed. This page contains information you need to know when migrating from deprecated API versions to newer and more stable API versions.

For details please refer to the [official Kubernetes documentation](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)

---

## Troubleshooting

### AKS Node Pool Provisioning State Failed

The Terraform Apply phase will report an error if a node pool `Provisioning State` returns a status of `Failed`. Follow the guides below to troubleshoot the issue. During testing all encountered errors have been recoverable.

[I'm receiving errors that my cluster is in failed state during an upgrade due to PodDisruption Budgets](#pod-disruption-budgets)

[I'm receiving errors that my cluster is in failed state and upgrading or scaling will not work until it is fixed](https://docs.microsoft.com/en-us/azure/aks/troubleshooting#im-receiving-errors-that-my-cluster-is-in-failed-state-and-upgrading-or-scaling-will-not-work-until-it-is-fixed)

[I'm getting an insufficientSubnetSize error while deploying an AKS cluster with advanced networking. What should I do?](https://docs.microsoft.com/en-us/azure/aks/troubleshooting#im-receiving-errors-when-trying-to-upgrade-or-scale-that-state-my-cluster-is-being-upgraded-or-has-failed-upgrade)

[I'm getting a quota exceeded error during creation or upgrade. What should I do?](https://docs.microsoft.com/en-us/azure/aks/troubleshooting#im-getting-a-quota-exceeded-error-during-creation-or-upgrade-what-should-i-do)

During testing all encountered errors have been recoverable, for example if you encountered a `insufficientSubnetSize` error it maybe because you have more than one node pool in a given subnet.

- Wait until all node pools `Provisioning State` returns a status either a `Succeeded` or `Failed`.- Then using the `az cli` or the `Azure Portal` for the node pools that have a `Provisioning State` of `Failed` change the `Scale node pool` setting from `Autoscale` to `Manual` with the same `min` - `max` settings.
- This will trigger a scaling event and a new node will be provisioned with the later Kubernetes `minor` or `patch` version.
- Wait until the `Provisioning State` has changed to `Succeeded` and repeat these steps for the next node pool that has a `Provisioning State` of `Failed` until all node pools have a `Provisioning State` of `Succeeded`

The same steps can be carried out after resolving errors associated with PodDisruptionBudgets (#pod-disruption-budgets)

If you have followed all the troubleshooting steps and you cannot get the node pool `Provisioning State` to a Succeeded status consider logging a [support request](https://docs.microsoft.com/en-us/azure/azure-portal/supportability/how-to-create-azure-support-request) in the Azure portal.

### Terraform Plan Failed

`Provider configuration not present`  errors during a Terraform `Plan`, please make sure you have followed all the steps in the [Upgrading Module Versions](#upgrading-module-versions) and [Upgrading Kubernetes Minor Versions](#upgrading-kubernetes-minor-versions)

### Terraform Apply Failed

`Cycle` errors during a Terraform `Apply`, please make sure you have followed all the steps in the [Upgrading Module Versions](#upgrading-module-versions) and [Upgrading Kubernetes Minor Versions](#upgrading-kubernetes-minor-versions)

`Conflicts with "HashiCorp" using apiextensions.k8s.io/v1` errors during a Terraform `Apply`, please make sure you have followed all the steps in the [Upgrading Module Versions](#upgrading-module-versions) and [Upgrading Kubernetes Minor Versions](#upgrading-kubernetes-minor-versions)
