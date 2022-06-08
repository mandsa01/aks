# cert-manager

[cert-manager](https://cert-manager.io/docs/) is an agent for Kubernetes that manages TLS certificates and certificate issuers. It's intended to facilitate and automate the creation and lifecycle of TLS certificates. Briefly, you configure an issuer against a provider with an API (such as [LetsEncrypt](letsencrypt.org/)), then request certificates through that issuer. cert-manager will then manage the certificate throughout its life, including renewals.

We're implementing cert-manager as part of our Kubernetes core config so that TLS support is built in. By default, a cluster issuer called `letsencrypt-issuer` will always be created for LetsEncrypt and a list of domains that you must provide.

As there is abundant documentation online on how to use cert-manager, this README focuses only on the input variables you need to provide when setting up your Kubernetes cluster.

## Usage

The AKS module has an input variable called `core_services_config` through which you can pass bits of config to this submodule like so:

```
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    cert_manager = {
      ...
    }
    ...
  }
}
```

The `cert_manager` block is just a key-value map that expects the following keys:

`letsencrypt_environment`: must be `staging` or `production`
`letsencrypt_email`: the email address set on the issuer, the issuer will send emails to that address, such as certificate expiration alerts
`dns_zones`: a map of domain names -> resource groups that your certificates will use
`additional_issuers`: a way to configure issuers in addition to the default

Concrete example:

```
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    cert_manager = {
      azure_environment = "AzurePublicCloud"
      letsencrypt_environment = "production"
      letsencrypt_email = "your.team@lexisnexisrisk.com"
      dns_zones = {
        "domain.lnrsg.io" = "azure-resource-group-name"
      }
    }
  }
}
```

For additional issuers, see the cert-manager documentation as the implementation will vary. See also [this chunk of code](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/blob/429f46386cbcf355e437aec74d234029e0ff1981/modules/core-config/modules/cert-manager/local.tf#L136-L164) showing how the default LetsEncrypt issuer is configured, you can use that as a base for configuring your own issuer if needed.

## Wildcard Certificate

When deploying the cert-manager module a wildcard certificate is generated to overcome the [rate limits](https://letsencrypt.org/docs/rate-limits/) for new certificate requests imposed by lets-encrypt.

A wildcard certificate is generated that contains a list of wildcard entries listed from the `dns_zones` map of domains.

This uses the `letsencrypt-issuer` cluster issuer to generate a certificate and secret named `default-wildcard-cert-tls` in the cert-manager namespace.

The ingress-core-internal nginx controller is configured to use this as the [default ssl certificate](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#default-ssl-certificate).

The default certificate will be used for ingress tls: sections that do not have a secretName option.

```
      extraArgs = {
        "default-ssl-certificate" = "cert-manager/default-wildcard-cert-tls"
      }
```

Below is an example of an ingress object that uses the default wildcard certificate.

```
grafana:
  ingress:
    enabled: true
    hosts:
    - grafana-iob-dev-westeurope-akstest.test.iob.azure.lnrsg.io
    ingressClassName: core-internal
    path: /
    pathType: Prefix
    tls:
    - hosts:
      - grafana-iob-dev-westeurope-akstest.test.iob.azure.lnrsg.io
```

Notice that the `secretName` option is missing under the ingress tls section and there is no annotation needed for `cert-manager.io/cluster-issuer`