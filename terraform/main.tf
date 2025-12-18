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

# 1. Recupera o Resource Group existente
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Storage Account (Obrigatório para a Function funcionar)
resource "azurerm_storage_account" "sa_func" {
  name                     = "stfuncsoat12fsmt" # Deve ser único globalmente
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (Consumption / Serverless)
resource "azurerm_service_plan" "asp" {
  name                = "asp-func-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Y1 = Serverless (Paga por execução)
}

# 4. A Function App (Node.js)
resource "azurerm_linux_function_app" "func_app" {
  name                = "func-auth-soat12" # URL: https://func-auth-soat12.azurewebsites.net
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa_func.name
  storage_account_access_key = azurerm_storage_account.sa_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "18"
    }
    # Cors (opcional, mas bom para evitar erro se chamar do front)
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    # Placeholder: As variáveis reais (DB e JWT) serão injetadas via App Settings no Portal ou CLI
  }
}

output "function_app_name" {
  value = azurerm_linux_function_app.func_app.name
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.func_app.default_hostname
}