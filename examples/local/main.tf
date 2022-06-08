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

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {
  subscription_id = module.subscription.output.subscription_id
}

data "azuread_group" "subscription_owner" {
  display_name = "ris-azr-group-${data.azurerm_subscription.current.display_name}-owner"
}

locals {
  cluster_name_short = trimprefix(local.cluster_name, "${local.account_code}-")

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

  grafana_admin_password = random_string.random.result

  alert_manager_recievers = []
  alert_manager_routes    = []

  azure_auth_env = {
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
    env         = local.azure_auth_env
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
    args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
    env         = local.azure_auth_env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.aks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", "--login", "azurecli"]
      env         = local.azure_auth_env
    }
  }

  experiments {
    manifest = true
  }
}

provider "shell" {
  sensitive_environment = local.azure_auth_env
}

resource "random_string" "random" {
  length  = 12
  upper   = false
  number  = false
  special = false
}

module "subscription" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"

  subscription_id = data.azurerm_client_config.current.subscription_id
}

module "naming" {
  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-naming.git?ref=v1.0.81"
}

module "metadata" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.5.1"

  naming_rules = module.naming.yaml

  market              = "us"
  project             = "https://gitlab.ins.risk.regn.net/example/"
  location            = "eastus"
  environment         = "sandbox"
  product_name        = random_string.random.result
  business_unit       = "iog"
  product_group       = "demo"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "dev"
  resource_group_type = "app"
}

module "resource_group" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "git@github.com:Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v6.0.0"

  naming_rules = module.naming.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  enforce_subnet_names = false

  address_space = ["10.1.0.0/22"]

  aks_subnets = {
    demo = {
      subnet_info = {
        cidrs = ["10.1.0.0/24"]
      }
      route_table = {
        disable_bgp_route_propagation = true
        routes = {
          internet = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
          local-vnet-10-1-0-0-22 = {
            address_prefix = "10.1.0.0/22"
            next_hop_type  = "VnetLocal"
          }
        }
      }
    }
  }
}

module "aks" {
  depends_on = [
    module.virtual_network
  ]

  source = "git@github.com:LexisNexis-RBA/terraform-azurerm-aks.git"

  location            = module.metadata.location
  resource_group_name = module.resource_group.name

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  network_plugin  = "kubenet"
  sku_tier_paid   = false

  cluster_endpoint_public_access = true
  cluster_endpoint_access_cidrs  = ["0.0.0.0/0"]

  virtual_network_resource_group_name = module.resource_group.name
  virtual_network_name                = module.virtual_network.vnet.name
  subnet_name                         = module.virtual_network.aks.demo.subnet.name
  route_table_name                    = module.virtual_network.aks.demo.route_table.name

  dns_resource_group_lookup = { "${local.internal_domain}" = local.dns_resource_group }

  admin_group_object_ids = [data.azuread_group.subscription_owner.object_id]

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
      public_dns       = true
    }
  }

  tags = module.metadata.tags
}