# Storage classes submodule

## Description

A module to create [Kubernetes storage classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) in accordance with company standards.

> as storage classes are cloud-specific, this module exists only as a submodule of this AKS module

Storage classes created by this module:

- `azure-disk-standard-ssd-retain`: Azure Managed Disk in Standard SSD tier, with reclaim policy "Retain"
- `azure-disk-premium-ssd-retain`: Azure Managed Disk in Premium SSD tier, with reclaim policy "Retain"
- `azure-disk-standard-ssd-delete`: Azure Managed Disk in Standard SSD tier, with reclaim policy "Delete"
- `azure-disk-premium-ssd-delete`: Azure Managed Disk in Premium SSD tier, with reclaim policy "Delete"
- `local-nvme-delete`: Provisions volumes on disks matching "nvme*"
- `local-ssd-delete`: Provisions volumes on disks matching "sdb1*"

This module has some logic to check the cluster version. If the `cluster_version` is set to 1.20 or below using the storage drivers that are part of the core Kubernetes code referred to as `in-tree` drivers are used for `azure-disk-standard-ssd-retain`, `azure-disk-premium-ssd-retain`, `azure-disk-standard-ssd-delete` and `azure-disk-premium-ssd-delete`. If the `cluster_version` is set to 1.21 or above then the new [CSI drivers](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers) are used which are plug-ins.

Starting in Kubernetes version 1.21, Kubernetes will use CSI drivers only and by default. These drivers are the future of storage support in Kubernetes. If you have created custom storage classes based on the `in-tree` storage drivers, these will need to be migrated when you have upgraded your cluster to 1.21.x. For more details on how to migrate please visit [here](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers#migrating-custom-in-tree-storage-classes-to-csi).

If you are creating a new 1.21.x cluster or above of upgrading from a 1.20.x cluster to 1.21.x cluster then you will need to be targeting `v1.0.0-beta.7` or above.

> **IMPORTANT** - When upgrading from a 1.20.x cluster to a 1.21.x cluster you must delete the following storage classes prior to the upgrade (`azure-disk-standard-ssd-retain`, `azure-disk-premium-ssd-retain`, `azure-disk-standard-ssd-delete` and `azure-disk-premium-ssd-delete`)

 The command below needs to run by a cluster operator with permissions to delete resources.

```console
kubectl delete storageclass azure-disk-premium-ssd-delete azure-disk-premium-ssd-retain azure-disk-standard-ssd-delete azure-disk-standard-ssd-retain
```

**Note**: AKS provisions a set of default storage classes which are protected by a Kubernetes Reconciliation loop. One of those storage classes is called `default`, is set as a cluster default, cannot be overridden by any means ([by design](https://docs.microsoft.com/en-us/azure/aks/concepts-storage#storage-classes)), and its main attributes are Azure Managed Disk + Standard SSD tier + reclaim policy = "Delete".

What that means is if you create a persistent volume (PV) and don't specify a storage class, this default built-in storage class will be applied to your PV, and since its reclaim policy is set to "Delete", the PV will be deleted if the associated persistent volume claim (PVC) is deleted ([reference](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)). This may lead to data loss.

In short, avoid using this built-in default storage class, unless its settings meet your needs and you understand the implications of its reclaim policy being set to "Delete".
