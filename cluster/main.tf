terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  version = "~>2.00"
  features {}
}

resource "azurerm_resource_group" "cluster" {
  name     = "${var.rp_prefix}-rp-rg"
  location = var.rp_resource_group_location_1
}

module "location-1" {
  source = "../modules/cluster"

  prefix                              = var.rp_prefix
  cluster_type                        = "location-1"
  resource_group_name                 = azurerm_resource_group.cluster.name
  location                            = var.rp_resource_group_location_1
}

module "location-2" {
  source = "../modules/cluster"

  prefix                              = var.rp_prefix
  cluster_type                        = "location-2"
  resource_group_name                 = azurerm_resource_group.cluster.name
  location                            = var.rp_resource_group_location_2
}

module "location-3" {
  source = "../modules/cluster"

  prefix                              = var.rp_prefix
  cluster_type                        = "location-3"
  resource_group_name                 = azurerm_resource_group.cluster.name
  location                            = var.rp_resource_group_location_3
}