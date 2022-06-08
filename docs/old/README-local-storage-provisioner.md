# Local Volume Provisioner

## Description

A module to install the local volume provisioner in AKS

**Note**: Local NVMe/SSD disks are ephemeral, data will be lost on these disks if you stop/deallocate your VM. Local NVMe disk aren't encrypted by Azure Storage encryption, even if you enable encryption at host.