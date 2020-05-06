provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "DaisukeiFrontDoorExampleResourceGroup"
  location = "EastUS2"
}

resource "azurerm_frontdoor" "example" {
  name                                         = "daisukei-example-FrontDoor"
  resource_group_name                          = azurerm_resource_group.example.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "exampleRoutingRule1"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["daisukeiExampleFrontendEndpoint1"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "exampleBackendBing"
    }
  }

  backend_pool_load_balancing {
    name = "exampleLoadBalancingSettings1"
  }
    
  backend_pool_health_probe {
    name = "exampleHealthProbeSetting1"
  }

  backend_pool {
    name = "exampleBackendBing"

    backend {
      host_header = "www.google.com"
      address     = "www.google.com"
      http_port   = 80
      https_port  = 443
      priority    = 1
      weight      = 40
      enabled     = true
    }

    backend {
      host_header = "www.bing.com"
      address     = "www.bing.com"
      http_port   = 80
      https_port  = 443
      priority    = 1
      weight      = 60
      enabled     = true
    }

    load_balancing_name = "exampleLoadBalancingSettings1"
    health_probe_name   = "exampleHealthProbeSetting1"
  }

  frontend_endpoint {
    name                              = "daisukeiExampleFrontendEndpoint1"
    host_name                         = "daisukei-example-FrontDoor.azurefd.net"
    custom_https_provisioning_enabled = false
  }
}
