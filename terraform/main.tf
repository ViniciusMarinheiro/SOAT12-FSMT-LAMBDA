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

# 1. Recupera o Resource Group (que está em East US 2)
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Storage Account
resource "azurerm_storage_account" "sa_func" {
  name                     = "stfuncsoat12fsmt"
  resource_group_name      = data.azurerm_resource_group.rg.name
  
  # VOLTAMOS PARA A REGIÃO DO GRUPO (East US 2)
  location                 = data.azurerm_resource_group.rg.location 
  
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (B1 em East US 2)
resource "azurerm_service_plan" "asp" {
  name                = "asp-func-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  
  # VOLTAMOS PARA A REGIÃO DO GRUPO
  location            = data.azurerm_resource_group.rg.location
  
  os_type             = "Linux"
  sku_name            = "B1" # Mantemos B1 pois é o mais seguro para cota
}

# 4. A Function App
resource "azurerm_linux_function_app" "func_app" {
  name                = "func-auth-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  
  # VOLTAMOS PARA A REGIÃO DO GRUPO
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa_func.name
  storage_account_access_key = azurerm_storage_account.sa_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "18"
    }
    always_on = true 
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
  }
}

output "function_app_name" {
  value = azurerm_linux_function_app.func_app.name
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.func_app.default_hostname
}