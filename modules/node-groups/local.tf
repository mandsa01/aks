locals {
  az_count = length(var.availability_zones)

  placement_group_keys  = distinct(compact([for n in var.node_group_templates : n.placement_group_key if !n.single_group]))
  placement_group_names = flatten([for k in local.placement_group_keys : [for z in var.availability_zones : "${k}${z}"]])

  system_node_group_template = {
    name                = "system"
    system              = true
    node_os             = "ubuntu"
    node_type           = "gp"
    node_type_version   = "v1"
    node_size           = "xlarge"
    single_group        = false
    min_capacity        = local.az_count
    max_capacity        = local.az_count * 4
    placement_group_key = null
    labels = {
      "lnrs.io/tier" = "system"
    }
    taints = [{
      key    = "CriticalAddonsOnly"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
    tags = {}
  }

  node_group_templates = concat([local.system_node_group_template], [for template in var.node_group_templates : merge(template, { system = false })])

  node_group_templates_pass_1 = concat(flatten([for template in local.node_group_templates : [for az in var.availability_zones : merge(template, {
    availability_zones = [az]
    az                 = az
    min_capacity       = floor(template.min_capacity / local.az_count)
    max_capacity       = floor(template.max_capacity / local.az_count)
    })] if !template.single_group]),
    [for template in local.node_group_templates : merge(template, {
      availability_zones = var.availability_zones
      az                 = 0
    }) if template.single_group]
  )

  node_group_templates_pass_2 = [for template in local.node_group_templates_pass_1 : merge(template, { name = format("%s%s", template.name, template.az) })]

  node_groups = [for template in local.node_group_templates_pass_2 : merge(template, {
    proximity_placement_group_id = template.single_group || template.placement_group_key == null || template.placement_group_key == "" ? null : azurerm_proximity_placement_group.default["${template.placement_group_key}${template.az}"].id
  })]

  system_node_groups = { for group in local.node_groups : group.name => group if group.system }
  user_node_groups   = { for group in local.node_groups : group.name => group if !group.system }
}
