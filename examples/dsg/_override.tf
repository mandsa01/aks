locals {
  account_code = ""
  # example: "ioa"

  cluster_name = ""
  # example: "ioa-aks-1"

  cluster_version = ""
  # example: "1.21"

  podnet_cidr_block = ""
  # example: "100.65.0.0/16"

  cluster_admin_users = {}
  # example: { "user@b2b.regn.net" = "aaa-bbb-ccc-ddd-eee" }

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
}
