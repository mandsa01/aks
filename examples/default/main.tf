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

locals {
  location = data.azurerm_resource_group.default.location
}

provider "azurerm" {
  tenant_id       = local.azure_auth_env["AZURE_TENANT_ID"]
  subscription_id = local.azure_auth_env["AZURE_SUBSCRIPTION_ID"]
  client_id       = local.azure_auth_env["AZURE_CLIENT_ID"]
  client_secret   = local.azure_auth_env["AZURE_CLIENT_SECRET"]

  features {
  }
}

provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env["AZURE_TENANT_ID"]]
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
    args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env["AZURE_TENANT_ID"]]
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
      args        = ["get-token", "--login", "spn", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--environment", "AzurePublicCloud", "--tenant-id", local.azure_auth_env["AZURE_TENANT_ID"]]
      env         = local.k8s_exec_auth_env
    }
  }
}

provider "shell" {
  sensitive_environment = local.azure_auth_env
}

module "aks" {
  source = "git::https://github.com/LexisNexis-RBA/terraform-azurerm-aks.git?ref=v1"

  location            = local.location
  resource_group_name = data.azurerm_resource_group.default.name

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  network_plugin  = "kubenet"
  sku_tier_paid   = false

  cluster_endpoint_public_access = true
  cluster_endpoint_access_cidrs  = ["0.0.0.0/0"]

  virtual_network_resource_group_name = data.azurerm_subnet.default.resource_group_name
  virtual_network_name                = data.azurerm_subnet.default.virtual_network_name
  subnet_name                         = data.azurerm_subnet.default.name
  route_table_name                    = data.azurerm_route_table.default.name

  dns_resource_group_lookup = { "${local.internal_domain}" = data.azurerm_resource_group.dns.name }

  podnet_cidr_block = local.podnet_cidr_block

  azuread_clusterrole_map = {
    cluster_admin_users  = {}
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

  core_services_config = {
    alertmanager = {
      smtp_host = "smtp.rbxd.ds:25"
      smtp_from = "${local.cluster_name}@reedbusiness.com"
    }

    ingress_internal_core = {
      domain = local.internal_domain
    }
  }

  tags = {
    "my-tag" = "TEST"
  }
}
