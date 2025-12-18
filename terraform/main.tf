terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-soat12"
    storage_account_name = "stterraformstate12soat"
    container_name       = "tfstate"
    key                  = "lambda.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# 1. Recupera o Resource Group (East US 2)
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Storage Account
# Mantivemos o nome v3 para garantir unicidade
resource "azurerm_storage_account" "sa_func" {
  name                     = "stfuncsoat12fsmtv3"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (MUDANÇA: WINDOWS)
# Mudamos para Windows para usar um "balde" de cota diferente
resource "azurerm_service_plan" "asp" {
  name                = "asp-func-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  
  os_type             = "Windows" # <--- MUDANÇA CRÍTICA
  sku_name            = "B1"      # Basic Tier
}

# 4. A Function App (MUDANÇA: WINDOWS FUNCTION)
# Note que o recurso agora é "azurerm_windows_function_app"
resource "azurerm_windows_function_app" "func_app" {
  name                = "func-auth-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa_func.name
  storage_account_access_key = azurerm_storage_account.sa_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "~18" # Sintaxe para Node no Windows Function
    }
    # Always On ligado no plano B1
    always_on = true
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
  }
}

output "function_app_name" {
  value = azurerm_windows_function_app.func_app.name
}

output "function_app_default_hostname" {
  value = azurerm_windows_function_app.func_app.default_hostname
}