# coredns

Azure Kubernetes Service (AKS) uses the [CoreDNS project](https://coredns.io/) for cluster DNS management and resolution with all 1.12.x and higher clusters.

DNS support in AKS for both kubenet and Azure CNI plugins is managed by CoreDNS. Coredns runs as managed deployment running in AKS with its own autoscaler. CoreDNS by default is configured to forward unknown domains to the DNS functionality of the Azure Virtual Network where the AKS cluster is deployed. Hence, Azure DNS and Private Zones will work for pods running in AKS.

As AKS is a managed service, you cannot modify the main configuration for CoreDNS (a CoreFile). Instead, you use a [Kubernetes ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) to override the default settings.

For more information on how to customize coredns in AKS see [here](https://docs.microsoft.com/en-us/azure/aks/coredns-custom)

This modules purpose is to provide the means to resolve on-premise dns domains from within the AKS cluster. The module takes a single input named `forward_zones` which is a map of dns zone names and a ip address(s) of the dns servers associated with that domain.

DNS forwarding is the process by which particular sets of DNS queries are forwarded to a designated server for resolution according to the DNS domain name in the query rather than being handled by the initial server that was contacted by the client.

Once the coredns `forward_zones` input has been configured a configmap named `coredns-custom` will be created in the kube-system namespace. The `coredns-custom` configmap is configured to forward dns requests for a specified on-premise domain to the domains dns servers. An example of the configmap manifest can be seen below.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  onpremzones.server: |
    b2b.regn.net:53 {
        forward . 10.52.24.10 10.52.24.11
    }
    rbi.web.ds:53 {
        forward . 10.52.24.10 10.52.24.11
    }
    risk.regn.net:53 {
        forward . 10.239.0.135
    }
```

The ip addresses can change for the DNS servers that support an on-premise domains. If you are unsure of the current list of DNS servers for a on-premise domain please contact your internal support teams that look after DNS.

In a future update to this coredns module the idea is to provide a lookup service managed by the teams responsible for DNS. This in turn will be used as a data source for the coredns module so the ip address(s) will be auto completed for each domain.

## Usage

The AKS module has an input variable called `core_services_config` through which you can pass bits of config to this submodule.

The `coredns` block is just a key-value map, for a list of of available input variables for coredns look at the main [README](/README.md#Appendix-O), Appendix O.

- `forward_zones`: The map of DNS zones and DNS server IP addresses to forward to dns requests to.

`Note` The ip address can be a single entry or a list, if there is a list of ip addresses then this will need to be space delimited.

Below is an example configuration that adds the `forward_zones` map to configure the custom coredns configmap.

```terraform
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    coredns = {
      forward_zones = {"b2b.regn.net" = "10.52.24.10 10.52.24.11"
                       "rbi.web.ds" = "10.52.24.10 10.52.24.11"
                       "risk.regn.net" = "10.239.0.135"
                      }
    }
    ...
  }
}
```

`Note`: For coredns forwarding to work the necessary network infrastructure will need to be in place to allow connectivity between the AKS cluster and the on-premise or cloud based DNS servers.

Once the configmap has been deployed you can check that it resides in the kube-system namespace.

```bash
$ kubectl get configmaps -n kube-system

NAME                                      DATA   AGE
coredns-custom                            1      55m
```

Coredns will automatically reload once the configmap has been deployed, this runs on a 30 second interval.

To check name resolution you can use the `busybox:1.28.0` image which has nslookup tool installed.

```bash
$ kubectl run test-ns --image=busybox:1.28.0 --rm -it --restart=Never -- nslookup b2b.regn.net
```

`Note:` Change b2b.regn.net to the domain name you are testing.
