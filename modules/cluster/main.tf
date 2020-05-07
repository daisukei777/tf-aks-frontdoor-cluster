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

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        OID=$(az ad app show --id "https://${var.prefix}-rp-sp-aks-${var.cluster_type}" -o tsv --query objectId)
        if [ -n "$OID" ]; then
            echo "Completed Azure AD Replication (App)"
            break
        else
            echo "Waiting for Azure AD Replication (App)..."
            sleep 5
        fi
    done
    
EOT
  }
}

resource "azuread_service_principal" "aks" {
  application_id = azuread_application.aks.application_id

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
  command = <<EOT
  while :
  do
      SP_OID=$(az ad sp show --id "https://${var.prefix}-rp-sp-aks-${var.cluster_type}" -o tsv --query objectId)
      if [ -n "$SP_OID" ]; then
          echo "Completed Azure AD Replication (SP)"
          break
      else
          echo "Waiting for Azure AD Replication (SP)..."
          sleep 5
      fi
  done
    
EOT
  }
}

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "aks" {
  end_date             = "2299-12-30T23:00:00Z" # Forever
  service_principal_id = azuread_service_principal.aks.id
  value                = random_string.password.result

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        SP_OID=$(az ad sp show --id "https://${var.prefix}-rp-sp-aks-${var.cluster_type}" -o tsv --query objectId)
        if [ -n "$SP_OID" ]; then
            echo "Completed Azure AD Replication (SP Password)"
            break
        else
            echo "Waiting for Azure AD Replication (SP Password)..."
            sleep 5
        fi
    done
    
EOT

  }
}

resource "azurerm_role_assignment" "aks" {
  depends_on           = [azuread_service_principal_password.aks]
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.aks.id

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = "sleep 30"
  }
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

provider "kubernetes" {
  version          = "~>1.5"
  load_config_file = false
  host             = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate = base64decode(
    azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate,
  )
  client_key = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(
    azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate,
  )
}

resource "kubernetes_service" "todoapp" {
  depends_on = [azurerm_kubernetes_cluster.aks]

  metadata {
    name = "todoapp"
  }

  spec {
    selector = {
      app = "todoapp"
    }

    session_affinity = "ClientIP"

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}


resource "kubernetes_deployment" "todoapp" {
  metadata {
    name = "todoapp"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "todoapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "todoapp"
        }
      }

      spec {
        container {
          image = "nginx:1.7.8"
          name  = "mytodoapp"

          port {
            container_port = 8080
          }

          resources {
            limits {
              cpu    = "250m"
              memory = "100Mi"
            }

            requests {
              cpu    = "250m"
              memory = "100Mi"
            }
          }
        }
      }
    }
  }
}

