terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  # Authenticate using a service principal, managed identity, or Azure CLI
}

provider "azuread" {
  tenant_id = var.tenant_id
  # Authenticate using a service principal, managed identity, or Azure CLI
}

resource "azuread_application" "powerbi_sp_app" {
  display_name = var.service_principal_name
}

resource "azuread_service_principal" "powerbi_sp" {
  application_id = azuread_application.powerbi_sp_app.application_id
}

module "common_report_1" {
  source                       = "../../modules/powerbi_report"
  report_name                  = "Common Report 1"
  report_path                  = "../../../reports/common/report1.pbix"
  workspace_id                 = var.workspace_id
  service_principal_id         = azuread_service_principal.powerbi_sp.id
  datasource_connection_string = "Server=${var.database_server_name};Database=${var.database_name};"
}

module "customer_a_bespoke_report" {
  source                       = "../../modules/powerbi_report"
  report_name                  = "Customer A Bespoke Report"
  report_path                  = "../../../reports/customerA/bespoke_report.pbix"
  workspace_id                 = var.workspace_id
  service_principal_id         = azuread_service_principal.powerbi_sp.id
  datasource_connection_string = "Server=${var.database_server_name};Database=${var.database_name};"
}
