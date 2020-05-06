output "prefix" {
  value = var.rp_prefix
}

output "resource_group_name" {
  value = azurerm_resource_group.cluster.name
}

output "resource_group_location" {
  value = azurerm_resource_group.cluster.location
}
