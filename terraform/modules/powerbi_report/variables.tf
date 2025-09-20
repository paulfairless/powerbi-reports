variable "report_name" {
  description = "The name of the Power BI report."
  type        = string
}

variable "report_path" {
  description = "The path to the .pbix file."
  type        = string
}

variable "workspace_id" {
  description = "The ID of the Power BI workspace."
  type        = string
}

variable "service_principal_id" {
  description = "The ID of the service principal to assign to the report."
  type        = string
}

variable "datasource_type" {
  description = "The type of the Power BI datasource (e.g., 'Sql')."
  type        = string
  default     = "Sql"
}

variable "datasource_connection_string" {
  description = "The connection string for the datasource."
  type        = string
}
