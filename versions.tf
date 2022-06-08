terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.1.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">=1.7.10"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.7.2"
    }
  }
}
