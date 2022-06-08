# monitor-diagnostic-settings

The AKS [control plane](https://docs.microsoft.com/en-us/azure/aks/monitor-aks#collect-resource-logs) component diagnostic logs are configured separately to other logs. Exposing the AKS control plane diagnostic logs will aid cluster operators to troubleshoot issues.

Azure [diagnostic settings](https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings) allow logs and metrics to be sent to three main Azure services - Log Analytics Workspace, Event Hub and Blob storage ('partner solution' has also recently been added as an output). Individual logs and metrics can be enabled per category. The same log catagories can be sent to all three destinations under one Diagnostic Setting. If there are different catagories required to separate outputs then individual Diagnostic Settings have to be created for each one.

In this module we automatically send logs to a log analytics workspace created by the module in the same resource group as the AKS cluster. There is also an option to supply an input variable to configure monitor diagnostic settings for a storage account.

## Usage

The AKS module has an input variable called `core_services_config` through which you can pass bits of config to this submodule.

The `monitor-diagnostic-settings` block is just a key-value map, for a list of of available input variables for monitor-diagnostic-settings look at the main [README](../../../../README.md), Appendix N.

- `storage_account_id`: Storage account id to store a secondary copy of diagnostic logs.

Below is an example configuration that adds the optional storage account id to configure monitor diagnostic settings.

```terraform
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    monitor-diagnostic-settings = {
      storage_account_id = azurerm_storage_account.optional.id
    }
    ...
  }
}
```

`Note`: The storage account will need to created outside of the module and the storage account id referenced in the core_services_config block. The storage account can be created using [terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace)
