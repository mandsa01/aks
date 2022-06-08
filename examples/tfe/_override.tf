locals {
  account_code = ""
  # example: "us-infra-dev"

  cluster_name = ""
  # example: "us-infra-dev-aks-000"

  cluster_version = ""
  # example : "1.21"

  cluster_admin_users = {}
  # example: { "user@risk.regn.net" = "aaa-bbb-ccc-ddd-eee" }

  internal_domain = ""
  # example: "us-infrastructure-dev.azure.lnrsg.io"

  dns_resource_group = ""
  # example: "app-dns-prod-eastus2"

  smtp_host = ""
  # example: "appmail-test.risk.regn.net"

  smtp_from = ""
  # example: "${local.cluster_name}@risk.regn.net"
}
