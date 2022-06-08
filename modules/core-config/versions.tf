terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
