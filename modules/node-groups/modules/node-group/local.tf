locals {
  node_arch = "amd64"

  os_types = {
    "ubuntu"  = "Linux"
    "windows" = "Windows"
  }

  os_skus = {
    "ubuntu"  = "Ubuntu"
    "windows" = null
  }

  vm_sizes = {
    "amd64-gp-v1" = {
      "large"    = "Standard_D2s_v4"
      "xlarge"   = "Standard_D4s_v4"
      "2xlarge"  = "Standard_D8s_v4"
      "4xlarge"  = "Standard_D16s_v4"
      "8xlarge"  = "Standard_D32s_v4"
      "12xlarge" = "Standard_D48s_v4"
      "16xlarge" = "Standard_D64s_v4"
    }

    "amd64-gp-v2" = {
      "large"    = "Standard_D2s_v5"
      "xlarge"   = "Standard_D4s_v5"
      "2xlarge"  = "Standard_D8s_v5"
      "4xlarge"  = "Standard_D16s_v5"
      "8xlarge"  = "Standard_D32s_v5"
      "12xlarge" = "Standard_D48s_v5"
      "16xlarge" = "Standard_D64s_v5"
      "24xlarge" = "Standard_D96s_v5"
    }

    "amd64-gpd-v1" = {
      "large"    = "Standard_D2ds_v4"
      "xlarge"   = "Standard_D4ds_v4"
      "2xlarge"  = "Standard_D8ds_v4"
      "4xlarge"  = "Standard_D16ds_v4"
      "8xlarge"  = "Standard_D32ds_v4"
      "12xlarge" = "Standard_D48ds_v4"
      "16xlarge" = "Standard_D64ds_v4"
    }

    "amd64-gpd-v2" = {
      "large"    = "Standard_D2ds_v5"
      "xlarge"   = "Standard_D4ds_v5"
      "2xlarge"  = "Standard_D8ds_v5"
      "4xlarge"  = "Standard_D16ds_v5"
      "8xlarge"  = "Standard_D32ds_v5"
      "12xlarge" = "Standard_D48ds_v5"
      "16xlarge" = "Standard_D64ds_v5"
      "24xlarge" = "Standard_D96ds_v5"
    }

    "amd64-mem-v1" = {
      "large"    = "Standard_E2s_v4"
      "xlarge"   = "Standard_E4s_v4"
      "2xlarge"  = "Standard_E8s_v4"
      "4xlarge"  = "Standard_E16s_v4"
      "8xlarge"  = "Standard_E32s_v4"
      "12xlarge" = "Standard_E48s_v4"
      "16xlarge" = "Standard_E64s_v4"
    }

    "amd64-mem-v2" = {
      "large"    = "Standard_E2s_v5"
      "xlarge"   = "Standard_E4s_v5"
      "2xlarge"  = "Standard_E8s_v5"
      "4xlarge"  = "Standard_E16s_v5"
      "8xlarge"  = "Standard_E32s_v5"
      "12xlarge" = "Standard_E48s_v5"
      "16xlarge" = "Standard_E64s_v5"
      "24xlarge" = "Standard_E96s_v5"
      "26xlarge" = "Standard_E104s_v5"
    }

    "amd64-memd-v1" = {
      "large"    = "Standard_E2ds_v4"
      "xlarge"   = "Standard_E4ds_v4"
      "2xlarge"  = "Standard_E8ds_v4"
      "4xlarge"  = "Standard_E16ds_v4"
      "8xlarge"  = "Standard_E32ds_v4"
      "12xlarge" = "Standard_E48ds_v4"
      "16xlarge" = "Standard_E64ds_v4"
    }

    "amd64-memd-v2" = {
      "large"    = "Standard_E2ds_v5"
      "xlarge"   = "Standard_E4ds_v5"
      "2xlarge"  = "Standard_E8ds_v5"
      "4xlarge"  = "Standard_E16ds_v5"
      "8xlarge"  = "Standard_E32ds_v5"
      "12xlarge" = "Standard_E48ds_v5"
      "16xlarge" = "Standard_E64ds_v5"
      "24xlarge" = "Standard_E96ds_v5"
      "26xlarge" = "Standard_E104ds_v5"
    }

    "amd64-cpu-v1" = {
      "large"    = "Standard_F2s_v2"
      "xlarge"   = "Standard_F4s_v2"
      "2xlarge"  = "Standard_F8s_v2"
      "4xlarge"  = "Standard_F16s_v2"
      "8xlarge"  = "Standard_F32s_v2"
      "12xlarge" = "Standard_F48s_v2"
      "16xlarge" = "Standard_F64s_v2"
      "18xlarge" = "Standard_F72s_v2"
    }

    "amd64-stor-v1" = {
      "2xlarge"  = "Standard_L8s_v2"
      "4xlarge"  = "Standard_L16s_v2"
      "8xlarge"  = "Standard_L32s_v2"
      "12xlarge" = "Standard_L48s_v2"
      "16xlarge" = "Standard_L64s_v2"
      "20xlarge" = "Standard_L80s_v2"
    }
  }

  vm_labels = {
    "amd64-gp"   = {}
    "amd64-gpd"  = { "lnrs.io/local-storage" = "true" }
    "amd64-mem"  = {}
    "amd64-memd" = { "lnrs.io/local-storage" = "true" }
    "amd64-stor" = { "lnrs.io/local-storage" = "true" }
  }

  vm_taints = {
    "amd64-gp"   = []
    "amd64-gpd"  = []
    "amd64-mem"  = []
    "amd64-memd" = []
    "amd64-stor" = []
  }

  max_pods = {
    azure   = 30
    kubenet = 110
  }

  taint_effects = {
    "NO_SCHEDULE"        = "NoSchedule"
    "NO_EXECUTE"         = "NoExecute"
    "PREFER_NO_SCHEDULE" = "PreferNoSchedule"
  }

  enable_auto_scaling = var.max_capacity > 0 && var.min_capacity != var.max_capacity
}
