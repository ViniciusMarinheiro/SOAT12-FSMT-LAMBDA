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
# Mudamos o nome para v4 para garantir um storage limpo
resource "azurerm_storage_account" "sa_func" {
  name                     = "stfuncsoat12fsmtv4"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (WINDOWS CONSUMPTION)
# Y1 = Serverless Puro (Dynamic). Não usa cota de "Basic VMs".
resource "azurerm_service_plan" "asp" {
  name                = "asp-func-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  
  os_type             = "Windows" 
  sku_name            = "Y1"      
}

# 4. A Function App (WINDOWS)
resource "azurerm_windows_function_app" "func_app" {
  name                = "func-auth-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa_func.name
  storage_account_access_key = azurerm_storage_account.sa_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "~18"
    }
    # Always On NÃO é suportado no plano Y1 (Consumption), deve ser false
    always_on = false 
    use_32_bit_worker = true # Otimização para planos free/consumption
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