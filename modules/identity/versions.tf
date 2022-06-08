terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
