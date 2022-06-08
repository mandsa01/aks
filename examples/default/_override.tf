locals {
  account_code = ""
  # example: "ioa"

  cluster_name = ""
  # example: "ioa-aks-1"

  cluster_version = ""
  # example: "1.21"

  podnet_cidr_block = ""
  # example: "100.65.0.0/16"

  resource_group_name = ""
  # example: "ioa-dev-westeurope-rg-aks-3"

  vnet_resource_group = ""
  # example: "ioa-dev-westeurope-aks-rg-network"

  vnet_name = ""
  # example: "ioa-dev-westeurope-aks-vnet"

  subnet_name = ""
  # example: "aksprivate"

  route_table_name = ""
  # example: "ioa-dev-westeurope-aks-route"

  dns_resource_group = ""
  # example: "ioa-dev-westeurope-aks-rg-dns"

  internal_domain = ""
  # example: "ioa.azure.lnrsg.io"

  k8s_exec_auth_env = {
    AAD_SERVICE_PRINCIPAL_CLIENT_ID     = ""
    AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = ""
  }

  azure_auth_env = {
    AZURE_TENANT_ID       = ""
    AZURE_SUBSCRIPTION_ID = ""
    AZURE_CLIENT_ID       = ""
    AZURE_CLIENT_SECRET   = ""
  }
}
