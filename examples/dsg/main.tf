terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "~> 1.7"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7.2"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.21"
    }
  }
}

data "azurerm_subnet" "default" {
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = local.vnet_name

  name = local.subnet_name
}

data "azurerm_route_table" "default" {
  resource_group_name = local.vnet_resource_group

  name = local.route_table_name
}

data "azurerm_resource_group" "default" {
  name = local.resource_group_name
}

data "azurerm_resource_group" "dns" {
  name = local.dns_resource_group
}

data "vault_generic_secret" "default" {
  path = "kv/${local.account_code}/infrastructure/${local.cluster_name}"
}

data "vault_generic_secret" "azure_creds" {
  path = "kv/terraform/azure/${substr(local.account_code, 0, 2)}/${local.account_code}/credentials"
}

locals {
  location = data.azurerm_resource_group.default.location

  cluster_name_short = trimprefix(local.cluster_name, "${local.account_code}-")

  public_access_cidrs  = ["0.0.0.0/0"]
  private_access_cidrs = []

  azuread_clusterrole_map = {
    cluster_admin_users  = local.cluster_admin_users
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }

  node_group_templates = [
    {
      name                = "workers"
      node_os             = "ubuntu"
      node_type           = "gp"
      node_type_version   = "v1"
      node_size           = "large"
      single_group        = false
      min_capacity        = 0
      max_capacity        = 18
      placement_group_key = null
      labels = {
        "lnrs.io/tier" = "standard"
      }
      taints = []
      tags   = {}
    }
  ]

  grafana_admin_password = data.vault_generic_secret.default.data["grafana_admin_password"]

  smtp_host = "smtp.rbxd.ds:25"
  smtp_from = "${local.cluster_name}@reedbusiness.com"

  alert_manager_recievers = []
  alert_manager_routes    = []

  k8s_exec_auth_env = {
    AAD_SERVICE_PRINCIPAL_CLIENT_ID     = data.vault_generic_secret.azure_creds.data["client_id"]
    AAD_SERVICE_PRINCIPAL_CLIENT_SECRET = data.vault_generic_secret.azure_creds.data["client_secret"]
  }

  azure_auth_env = {
    AZURE_TENANT_ID       = data.vault_generic_secret.azure_creds.data["tenant_id"]
    AZURE_SUBSCRIPTION_ID = data.vault_generic_secret.azure_creds.data["subscription_id"]
    AZURE_CLIENT_ID       = data.vault_generic_secret.azure_creds.data["client_id"]
    AZURE_CLIENT_SECRET   = data.vault_generic_secret.azure_creds.data["client_secret"]
  }

  tags = { for k, v in merge(var.pipeline_tags, var.market_tags, var.account_tags, var.project_tags) : replace(k, "/", "_") => v }
}

provider "vault" {
  address = "https://vault_eu_prod.b2b.regn.net"
}

provider "azurerm" {
  tenant_id       = data.vault_generic_secret.azure_creds.data["tenant_id"]
  subscription_id = data.vault_generic_secret.azure_creds.data["subscription_id"]
  client_id       = data.vault_generic_secret.azure_creds.data["client_id"]
  client_secret   = data.vault_generic_secret.azure_creds.data["client_secret"]

  features {
  }
}

provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", data.vault_generic_secret.azure_creds.data["tenant_id"]]
    env         = local.k8s_exec_auth_env
  }
}

provider "kubectl" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)
  load_config_file       = false
  apply_retry_count      = 6

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", data.vault_generic_secret.azure_creds.data["tenant_id"]]
    env         = local.k8s_exec_auth_env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", data.vault_generic_secret.azure_creds.data["tenant_id"]]
      env         = local.k8s_exec_auth_env
    }
  }
}

provider "shell" {
  sensitive_environment = local.azure_auth_env
}

provider "random" {}

provider "time" {}

module "aks" {
  source = "git::https://gitlab.b2b.regn.net/terraform/modules/Azure/terraform-azurerm-aks.git?ref=v1"

  location            = local.location
  resource_group_name = data.azurerm_resource_group.default.name

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  network_plugin  = "kubenet"
  sku_tier_paid   = false

  cluster_endpoint_public_access = true
  cluster_endpoint_access_cidrs  = concat(local.private_access_cidrs, local.public_access_cidrs)

  virtual_network_resource_group_name = data.azurerm_subnet.default.resource_group_name
  virtual_network_name                = data.azurerm_subnet.default.virtual_network_name
  subnet_name                         = data.azurerm_subnet.default.name
  route_table_name                    = data.azurerm_route_table.default.name

  dns_resource_group_lookup = { "${local.internal_domain}" = data.azurerm_resource_group.dns.name }

  podnet_cidr_block = local.podnet_cidr_block

  azuread_clusterrole_map = local.azuread_clusterrole_map

  node_group_templates = local.node_group_templates

  core_services_config = {
    alertmanager = {
      smtp_host = local.smtp_host
      smtp_from = local.smtp_from
      routes    = local.alert_manager_routes
      receivers = local.alert_manager_recievers
    }

    grafana = {
      admin_password = local.grafana_admin_password
    }

    ingress_internal_core = {
      domain           = local.internal_domain
      subdomain_suffix = local.cluster_name_short
    }
  }

  tags = local.tags
}

variable "pipeline_tags" {
  description = "Tags for the market."
  type        = map(string)
  default     = {}
}

variable "market_tags" {
  description = "Tags for the market."
  type        = map(string)
  default     = {}
}

variable "account_tags" {
  description = "Tags for the account."
  type        = map(string)
  default     = {}
}

variable "project_tags" {
  description = "Tags for the project."
  type        = map(string)
  default     = {}
}
# tflint-ignore: terraform_unused_declarations
variable "protected" {
  description = "If the pipeline should be protected."
  type        = bool
  default     = false
}
