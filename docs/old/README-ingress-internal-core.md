# Ingress

This guide describes how to deploy and use [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resources & controllers.

There are three types of ingress controllers typically deployed in a cluster.

* `Core` - to serve internal platform services via an internal load balancer
* `Private` - to serve private services via internal load balancer(s)
* `Public` - to serve internet-facing services via public load balancer(s)

---

## Core Ingress

The ingress for core platform services (*e.g. Prometheus, Grafana, Alertmanager*).

* ingressClassName: `core-internal`
* Namespace: `ingress-core-internal`

The ingress controller is hosted on the `system` nodepool to optimise resource usage, it is exposed via a private load balancer, to access it there must be internal connectivity from the client to the VNet. The URL for these services will depend on inputs to the `core_services_config` variable.

```yaml
  core_services_config = {
    ingress_internal_core = {
      domain           = "us-accurint-prod.azure.lnrsg.io"
      subdomain_suffix = "aks-1"
    }
  }
```

The URL format is `<service-name>-<subdomain_suffix>.<domain>` where `<service-name>` is either prometheus, grafana or alertmanager. The prometheus URL in the example above is `https://prometheus-aks-1.us-accurint-prod.azure.lnrsg.io`. If `subdomain_suffix` is not specified the cluster name is used.

__`NOTE`__ this ingress class is not intended to serve non-platform components - use a separate ingress tier and controller

---

## Standard Ingress

The first step is to deploy an ingress node pool to host the controller. 

The module provides an option to manage this pool automatically by setting the `ingress_node_group` variable to `true`. If this option is enabled, a scale set is deployed in the public subnet with appropriate labels and taints. The scale set consists or large instances that scale from 0-6 nodes.

If this does not meet your requirements, deploy a custom ingress tier via the `node_pools` variable.

```yaml
  node_pools = [
    {
      name        = "ingress"
      single_vmss = true
      public      = true
      vm_size     = "medium"
      os_type     = "Linux"
      min_count   = "3"
      max_count   = "12"
      taints = [{
        key    = "ingress"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      labels = {
        "lnrs.io/tier" = "ingress"
      }
      tags        = {}
    }
  ]
```

The next step is to deploy an ingress controller and ensure it sets the following options.

* It configures a custom [Ingress class](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class), for example `private-ingress` or `public`
* it tolerates the `ingress=true:NoSchedule` taint (or any custom taint) applied to this tier
* it uses the `lnrs.io/tier=ingress` nodeselector (or any custom node label) via the node label applied to this tier
* [externalTrafficPolicy](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip) is set to _**Local**_ to ensure traffic is routed directly to ingress nodes

### Private Ingress

A private ingress also requires the [service.beta.kubernetes.io/azure-load-balancer-internal](https://docs.microsoft.com/en-us/azure/aks/internal-lb#create-an-internal-load-balancer) annotation be set to _**true**_. 

Private load balancers are hosted within the Vnet, by default in the AKS private subnet but this can be changed - see [additional customizations via Kubernetes Annotations](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard#additional-customizations-via-kubernetes-annotations) for more details.

### Public Ingress

The public subnet Network Security Group (NSG) must allow internet traffic to the subnet via dedicated rules. 

Configure this via the [terraform-azure-virtual-network](https://github.com/Azure-Terraform/terraform-azurerm-virtual-network) module  