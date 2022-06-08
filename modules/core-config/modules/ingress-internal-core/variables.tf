variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "lb_subnet_name" {
  description = "Name of the subnets to create the LB in."
  type        = string
}

variable "lb_source_cidrs" {
  description = "CIDR range for LB traffic sources."
  type        = list(string)
}

variable "domain" {
  description = "The domain to use for internal ingress resources."
  type        = string
}

variable "certificate_issuer_kind" {
  description = "The certificate issuer kind."
  type        = string
}

variable "certificate_issuer_name" {
  description = "The certificate issuer."
  type        = string
}
