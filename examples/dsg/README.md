# Azure AKS Terraform Module - DSG Example

This example shows a DSG cluster configuration.

## Using this example

To use this example, the `main.tf` and `_override.tf` files can be copied to your workspace. The variables in the `_override.tf` file will need manually setting before any attempt to deploy the module.

## Cluster Users

If you want users to be able to connect to the AKS cluster with admin access, you'll need to specify their B2B address and object ID within the `cluster_admin_users` local variable. And example of this is given below.

```terraform
locals {
  cluster_admin_users = {
    "user@b2b.regn.net" = "aaa-bbb-ccc-ddd-eee"
  }
}
```

### Pipeline Settings

The project timeout setting can be found under `Settings` -> `CI/CD` -> `General pipelines` -> `Timeout`. This value should be set to `2h`.
