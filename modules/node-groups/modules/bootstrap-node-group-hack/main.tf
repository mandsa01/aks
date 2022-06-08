resource "shell_script" "default" {
  interpreter = ["/bin/bash", "-c"]

  environment = {
    "RESOURCE_GROUP_NAME" = var.resource_group_name
    "CLUSTER_NAME"        = var.cluster_name
    "SUBNET_ID"           = var.subnet_id
    "NODE_POOL_NAME"      = var.bootstrap_name
    "VM_SIZE"             = var.bootstrap_vm_size
  }

  lifecycle_commands {
    create = file("${path.module}/scripts/delete-default-node-pool.sh")
    read   = file("${path.module}/scripts/get-state.sh")
    update = file("${path.module}/scripts/no-op.sh")
    delete = file("${path.module}/scripts/create-default-node-pool.sh")
  }
}
