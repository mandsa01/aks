# fluentd

[Fluentd](https://docs.fluentd.org/v/0.12/) is a Ruby-based open-source log forwarder and aggregator. In the AKS module fluentd is configured as part of our Kubernetes core config as a `log aggregator`. Fluentd is configured as a Stateful set in the logging namespace that has affinity rules to create a replica in each of the availability zones for HA.

Fluentd uses a modified [fluentd docker image](https://github.com/stevehipwell/fluentd-aggregator) based on the official [fluentd docker image](https://github.com/fluent/fluentd-docker-image).

`Log aggregators` continuously receive events from the log forwarders, in this case `fluent-bit` that runs as a DaemonSet in the cluster. Fluentd's role in the cluster once the logs are received from `fluent-bit` is to buffer, filter, route and output logs to `supported storage services`. In a future release `fluentd` will be automatically configured to send logs to `Loki`.

Fluentd has a flexible plugin system that allows the community to extend its functionality, these are broken down into:

- Inputs
- Outputs
- Filters
- Routes

For a complete list of available plugins visit [here](https://www.fluentd.org/plugins). A link is available for each plugin with details on how to configure the plugin.

For a list of available plugins in the modified fluentd docker image please visit [here](https://github.com/stevehipwell/fluentd-aggregator). If there is a requirement for an additional plugin to be added please raise an issue against the [project](https://github.com/stevehipwell/fluentd-aggregator).

As there is abundant documentation online on how to use fluentd, this README focuses only on the input variables you need to provide when setting up your Kubernetes cluster.

## Usage

The AKS module has an input variable called `core_services_config` through which you can pass bits of config to this submodule like so:

```terraform
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    fluentd = {
      ...
    }
    ...
  }
}
```

The `fluentd` block is just a key-value map, for a list of of available input variables for fluentd look at the main [README](../../../../README.md), Appendix J.

- `image_repository`: Custom image repository to use for the Fluentd image, image_tag must also be set.
- `image_tag`: Custom image tag to use for the Fluentd image, image_repository must also be set.
- `additional_env`: Additional environment variables
- `debug`: If `true` all logs are printed to stdout.
- `pod_labels`: Labels to add to fluentd pods, used for pod-identity or cloud storage integrations.
- `filters`: Fluentd filter configuration.
- `routes`: Fluentd route configuration.
- `outputs`: Fluentd output configuration.

`Note`: `debug` is useful for troubleshooting, if set to `true` you can tail the fluentd logs

```bash
$kubectl logs -f fluentd-0 -n logging
```

Below is an example configuration that turns debug mode on and configures an output for Elasticsearch.

```terraform
module "aks" {
  source = "github.com/LexisNexis-RBA/terraform-azurerm-aks.git"
  ...
  core_services_config = {
    fluentd = {
      debug = "true"
      outputs = <<-EOT
        <label @DEFAULT>
          <match kube.var.log.containers.example-**.log>
            @type elasticsearch
            host example-eks-host.dev.app.lnrsg.io
            port 9200
            index_name fluentd
            type_name fluentd
          </match>
        </label>
      EOT
    }
    ...
  }
}
```
