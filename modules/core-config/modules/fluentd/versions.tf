terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
