# fluent-bit

[fluent-bit](https://docs.fluentbit.io/manual/installation/kubernetes) is a lightweight and extensible `log processor` that comes with full support for Kubernetes:

- Process Kubernetes containers logs from the file system or systemd/journald.
- Enrich logs with Kubernetes Metadata.
- Outputs logs to third party storage services like Elasticsearch, InfluxDB, HTTP, etc.

Fluent-bit is deployed as a DaemonSet in order for the agent to collect logs from every pod. When fluent-bit runs, it will read, parse and filter the logs of every pod and will enrich each entry with the following metadata using the [kubernetes filter](https://docs.fluentbit.io/manual/v/1.6/pipeline/filters/kubernetes):

- Pod Name
- Pod ID
- Container Name
- Container ID
- Labels
- Annotations

In the AKS module fluent-bit is configured to tail logs from `/var/log/containers` using the cri parser, this is due to containerd being the default runtime for AKS clusters using Kubernetes 1.19 and above.

[Multi-line support](https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/multiline-parsing) for the cri parser has been included in the fluent-bit module.

Fluent-bit is also configured to collect logs from the `containerd` and `kubelet` systemd units.

All logs are are then forwarded to the `fluentd` kubernetes service on port 24224. Even though other outputs / forwards are available for storage services such as Elasticsearch these are not configurable as the log workflow in the AKS module is `fluent-bit` -> `fluentd` -> `Other supported storage services`. In a future release `fluentd` will be configured to send logs to `Loki`.
