provider "azurerm" {
  version = "~>2.00"
  features {}
}

provider "azuread" {
  version = "~>0.1"
}

provider "random" {
  version = "~>2.0"
}

data "azurerm_subscription" "current" {
}

resource "azuread_application" "aks" {
  name            = "${var.prefix}-rp-sp-aks-${var.cluster_type}"
  identifier_uris = ["https://${var.prefix}-rp-sp-aks-${var.cluster_type}"]
}

resource "azuread_service_principal" "aks" {
  application_id = azuread_application.aks.application_id
}

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "aks" {
  end_date             = "2299-12-30T23:00:00Z" # Forever
  service_principal_id = azuread_service_principal.aks.id
  value                = random_string.password.result
}

resource "azurerm_role_assignment" "aks" {
  depends_on           = [azuread_service_principal_password.aks]
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.aks.id
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on          = [azurerm_role_assignment.aks]
  name                = "${var.prefix}-rp-aks-${var.cluster_type}"
  kubernetes_version  = "1.15.10"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.prefix}-rp-aks-${var.cluster_type}"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2s_v3"
  }

  service_principal {
    client_id     = azuread_application.aks.application_id
    client_secret = random_string.password.result
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }
}

