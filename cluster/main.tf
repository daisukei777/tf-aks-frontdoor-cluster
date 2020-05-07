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

resource "azurerm_frontdoor" "afd" {
  name                                         = "${var.rp_prefix}-rp-afd"
  resource_group_name                          = azurerm_resource_group.cluster.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "${var.rp_prefix}-rp-routing-rule"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["${var.rp_prefix}ep"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "${var.rp_prefix}bpn"
    }
  }

  backend_pool_load_balancing {
    name = "${var.rp_prefix}lbsetting"
  }
    
  backend_pool_health_probe {
    name = "${var.rp_prefix}hpsetting"
  }

  backend_pool {
    name = "${var.rp_prefix}bpn"

    backend {
      host_header = module.location-1.k8s_lb_ingress_ip
      address     = module.location-1.k8s_lb_ingress_ip
      http_port   = 80
      https_port  = 443
      priority    = 1
      weight      = 40
      enabled     = true
    }

    backend {
      host_header = module.location-2.k8s_lb_ingress_ip
      address     = module.location-2.k8s_lb_ingress_ip
      http_port   = 80
      https_port  = 443
      priority    = 1
      weight      = 60
      enabled     = true
    }

    backend {
      host_header = module.location-3.k8s_lb_ingress_ip
      address     = module.location-3.k8s_lb_ingress_ip
      http_port   = 80
      https_port  = 443
      priority    = 1
      weight      = 60
      enabled     = true
    }

    load_balancing_name = "${var.rp_prefix}lbsetting"
    health_probe_name   = "${var.rp_prefix}hpsetting"
  }

  frontend_endpoint {
    name                              = "${var.rp_prefix}ep"
    host_name                         = "${var.rp_prefix}-rp-afd.azurefd.net"
    custom_https_provisioning_enabled = false
  }
}
