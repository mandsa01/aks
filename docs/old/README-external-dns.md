# external-dns

[external-dns](https://github.com/kubernetes-sigs/external-dns) is an agent for Kubernetes that detects Kubernetes resources such as services or ingresses in your cluster, and creates/manages DNS records for those resources in a publicly-accessible DNS provider (such as AWS Route 53, Azure DNS and others).

We're integrating it as part of our Kubernetes core config so that your Kubernetes resources become  accessible immediately via DNS.

In Azure, every Azure subscription should be pre-provisioned with an Azure DNS zone that you should use. You can request additional DNS zones to be created if needed.

Currently the pattern is to use external-dns to create dns records in a Azure public DNS zone(s), the plan is to move to Azure private DNS zone(s) for internal dns records. You will need a matching Azure public zone for a split-horizon setup to enable cert-manager to create ACME TXT validation records.

Please continue to use Azure public DNS zone(s) until the setup is complete to resolve to Azure private DNS zones, once complete you can switch to Azure private DNS zone(s). 

## Usage

When creating your cluster, you'll have to use the `core_services_config` input variable to pass external-dns configuration down to the agent. Example:

```
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    external_dns = {
      public_resource_group_name  = "azure-resource-group-name"
      private_resource_group_name = "azure-resource-group-name"
      public_zones                = ["public.app.lnrsg.io"]
      private_zones               = ["staging.app.lnrsg.io", "dev.app.lnrsg.io"]
    }
  }
}
```

Please do not include `private_resource_group_name` and `private_zones` until notified, at which point we'll advise on a migration plan.

The public and private resource group name and list of zones are the only supported inputs.
