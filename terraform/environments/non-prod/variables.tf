variable "tenant_id" {
  description = "The ID of the Azure tenant."
  type        = string
}

variable "subscription_id" {
  description = "The ID of the Azure subscription."
  type        = string
}

variable "workspace_id" {
  description = "The ID of the Power BI workspace for non-prod."
  type        = string
}

variable "service_principal_name" {
  description = "The name of the service principal."
  type        = string
  default     = "powerbi-sp-non-prod"
}

variable "database_server_name" {
  description = "The name of the database server."
  type        = string
}

variable "database_name" {
  description = "The name of the database."
  type        = string
}
