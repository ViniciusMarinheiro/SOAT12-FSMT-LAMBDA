terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # Backend para salvar o estado na Azure (igual aos outros repos)
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

# 1. Recupera o Resource Group já existente (onde está o AKS e o Banco)
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Storage Account (Obrigatório para Functions)
# Forçamos "eastus" aqui para evitar erro de cota
resource "azurerm_storage_account" "sa_func" {
  name                     = "stfuncsoat12fsmt" # Nome único global (tente mudar se der erro de já existente)
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = "eastus" 
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (Consumption / Serverless)
# Forçamos "eastus" aqui também
resource "azurerm_service_plan" "asp" {
  name                = "asp-func-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus"
  os_type             = "Linux"
  sku_name            = "Y1" # Y1 = Gratuito/Pague pelo uso (Serverless puro)
}

# 4. A Function App (Node.js)
resource "azurerm_linux_function_app" "func_app" {
  name                = "func-auth-soat12" # Nome da URL: https://func-auth-soat12.azurewebsites.net
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus"

  storage_account_name       = azurerm_storage_account.sa_func.name
  storage_account_access_key = azurerm_storage_account.sa_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "18" # Define Node.js 18
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    # As variáveis de ambiente reais (DB_STRING, JWT_SECRET) 
    # serão injetadas via Portal ou GitHub Actions, não aqui.
  }
}

output "function_app_name" {
  value = azurerm_linux_function_app.func_app.name
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.func_app.default_hostname
}