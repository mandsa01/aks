terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
