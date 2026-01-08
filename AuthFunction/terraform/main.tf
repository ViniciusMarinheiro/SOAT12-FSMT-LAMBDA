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
    key                  = "auth.tfstate" # <--- IMPORTANTE: Estado isolado para Auth
  }
}

provider "azurerm" {
  features {}
}

# 1. Recupera o Resource Group existente
# O Terraform vai ler o grupo, não vai tentar recriá-lo.
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Storage Account EXCLUSIVA para a Function de Auth
# O nome deve ser único globalmente e diferente da storage da Notification
resource "azurerm_storage_account" "sa_func_auth" {
  name                     = "stauthsoat12fsmt" 
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Plano de Serviço (App Service Plan) para Auth
resource "azurerm_service_plan" "asp_auth" {
  name                = "asp-auth-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # B1 = Basic. Se quiser grátis (com limitações), use "Y1" (Consumption)
}

# 4. A Function App de Auth
resource "azurerm_linux_function_app" "func_app_auth" {
  name                = "func-auth-soat12"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa_func_auth.name
  storage_account_access_key = azurerm_storage_account.sa_func_auth.primary_access_key
  service_plan_id            = azurerm_service_plan.asp_auth.id

  site_config {
    application_stack {
      node_version = "18"
    }
    
    # "Always On" deve ser true para planos pagos (B1), false para Consumption (Y1)
    always_on = true 
    
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    # Adicione aqui outras variáveis de ambiente se precisar
  }
}

# Outputs úteis para visualizar após o apply
output "auth_function_name" {
  value = azurerm_linux_function_app.func_app_auth.name
}

output "auth_function_hostname" {
  value = azurerm_linux_function_app.func_app_auth.default_hostname
}