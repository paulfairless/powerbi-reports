output "report_id" {
  description = "The ID of the deployed Power BI report."
  value       = null_resource.powerbi_report.id
}
