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

# 1. Recupera o Resource Group (Já sabemos que está em East US 2)
data "azurerm_resource_group" "rg" {
  name = "rg-fsmt-soat12"
}

# 2. Azure Container Registry (ACR)
# Vai ser criado na mesma região do RG (East US 2)
# O SKU "Basic" é barato e não tem o problema de cota das VMs
resource "azurerm_container_registry" "acr" {
  name                = "acrsoat12fsmt" # Tudo minúsculo, deve ser único
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true # Importante: Habilita login para o GitHub Actions
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  value = azurerm_container_registry.acr.admin_password
  sensitive = true
}