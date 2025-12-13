terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # Backend para salvar o estado na Azure
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

# 1. Recupera o Resource Group já existente
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Storage Account (Obrigatório para Functions)
resource "azurerm_storage_account" "sa_func" {
  name                     = "stfuncsoat12fsmt" # Se der erro de nome em uso, mude aqui (ex: stfuncsoat12fsmtv2)
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = "eastus" # Forçamos East US para garantir disponibilidade
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (MUDANÇA CRÍTICA AQUI)
# Mudamos para F1 (Free Tier) para evitar o erro de cota "Dynamic VMs"
resource "azurerm_service_plan" "asp" {
  name                = "asp-func-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus"
  os_type             = "Linux"
  sku_name            = "F1" # F1 = Camada Gratuita (não é Dynamic/Serverless puro, mas funciona)
}

# 4. A Function App (Node.js)
resource "azurerm_linux_function_app" "func_app" {
  name                = "func-auth-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus"

  storage_account_name       = azurerm_storage_account.sa_func.name
  storage_account_access_key = azurerm_storage_account.sa_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "18"
    }
    # OBRIGATÓRIO: No plano F1, "always_on" deve ser false
    always_on = false 
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    # Lembrete: DB_CONNECTION_STRING e JWT_SECRET devem ser injetados via GitHub Actions ou Portal
  }
}

output "function_app_name" {
  value = azurerm_linux_function_app.func_app.name
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.func_app.default_hostname
}