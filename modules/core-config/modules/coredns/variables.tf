variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "forward_zones" {
  description = "Map of DNS zones and DNS server IP addresses to forward DNS requests to."
  type        = map(string)
}
