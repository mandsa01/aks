resource "random_password" "windows_admin_username" {
  count = var.windows_support ? 1 : 0

  length  = 8
  special = false
  number  = false
}

resource "random_password" "windows_admin_password" {
  count = var.windows_support ? 1 : 0

  length  = 14
  special = true
}
