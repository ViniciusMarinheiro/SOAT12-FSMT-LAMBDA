terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Configuração do Backend (Estado do Terraform)
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-soat12"
    storage_account_name = "stterraformstate12soat"
    container_name       = "tfstate"
    key                  = "notification.tfstate" # <--- IMPORTANTE: Estado isolado para Notification
  }
}

provider "azurerm" {
  features {}
}

# 1. Recupera o Resource Group existente
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Storage Account EXCLUSIVA para a Function de Notification
# Nome único e diferente da Auth
resource "azurerm_storage_account" "sa_func_notif" {
  name                     = "stnotifsoat12fsmt" 
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (App Service Plan) para Notification
resource "azurerm_service_plan" "asp_notif" {
  name                = "asp-notification-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Mantendo o padrão B1 (Basic)
}

# 4. A Function App de Notification
resource "azurerm_linux_function_app" "func_app_notif" {
  name                = "func-notification-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa_func_notif.name
  storage_account_access_key = azurerm_storage_account.sa_func_notif.primary_access_key
  service_plan_id            = azurerm_service_plan.asp_notif.id

  site_config {
    application_stack {
      node_version = "18"
    }
    
    # Always On true para evitar cold starts no plano B1
    always_on = true 
    
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    # Adicione aqui variáveis específicas de notificação (ex: chaves de SMTP/SendGrid)
  }
}

# Outputs úteis
output "notification_function_name" {
  value = azurerm_linux_function_app.func_app_notif.name
}

output "notification_function_hostname" {
  value = azurerm_linux_function_app.func_app_notif.default_hostname
}