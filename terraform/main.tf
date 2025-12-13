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

# Recupera o Resource Group existente (criado na Infra do AKS)
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# Storage Account para a Function App (Obrigatório)
resource "azurerm_storage_account" "sa_func" {
  name                     = "stfuncsoat12fsmt" # Nome deve ser unico globalmente, ajuste se der erro
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Plano de Serviço (Consumption Plan - Pague pelo uso, mais barato/grátis)
resource "azurerm_service_plan" "asp" {
  name                = "asp-func-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Y1 = Consumption Plan
}

# A Function App em si
resource "azurerm_linux_function_app" "func_app" {
  name                = "func-auth-soat12" # Nome único, será https://func-auth-soat12.azurewebsites.net
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa_func.name
  storage_account_access_key = azurerm_storage_account.sa_func.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "18" # Versão do Node.js
    }
  }

  app_settings = {
    # Aqui vamos injetar as configurações do código
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    # IMPORTANTE: Essas variáveis virão do GitHub Secrets no momento do deploy, 
    # ou você pode definir valores manuais aqui (não recomendado para senhas).
    # Vamos deixar placeholder e preencher via Portal ou GitHub App Settings.
  }
}

output "function_app_name" {
  value = azurerm_linux_function_app.func_app.name
}