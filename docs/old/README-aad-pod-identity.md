# AAD Pod Identity

## Description

AAD Pod Identity enables Kubernetes applications to access cloud resources securely with Azure Active Directory. This module will install/configure the required CRDs and helm chart in AKS.

## Service

The pod identity service runs a ReplicaSet and a DaemonSet.

* ReplicaSet - Managed Identity Controller (aad-pod-identity-mic) is a single pod that watches your running and checks whether they are tagged to have identities assigned to them. If these pods are tagged appropriately, it maintains an identity map connectivity pods to identities.
* DaemonSet - Node Managed Identity (aad-pod-identity-nmi) is the resource that is used when your pods look to use their identity. The applications running in the pod make a call to get their identity which is routed to the NMI instance on the node.  NMI then talks to the MIC to get the identity mapping and makes a request to Azure to retrieve the actual identity.

## Identities

It is required to use both the AzureIdentity and AzureIdentityBinding kubernetes resources.  The AzureIdentity will reference an Azure Managed Identity and the AzureIdentityBinding will reference the AzureIdentity.  The workflow is described [here](https://azure.github.io/aad-pod-identity/docs/demo/standard_walkthrough/#3-deploy-azureidentity).

For modules/identites contained within the AKS module, there is an identity [submodule](../../../identity) that can be used.

## CRD Updates

There is a [submodule](/crds/update_files) which should be used to manage [CRD](/crds) updates whenever the helm chart version is changed. To update CRDs, go into the subfolder and run `terraform init` and `terraform apply`.  The apply command will prompt for the version of the helm chart.  Once the desired version is specified, the plan will be shown with a prompt to apply.  Applying the plan will update the CRDs in the parent folder.  From there, add the updated files with git, commit the changes along with the associated helm chart version bump to new branch and create a PR.