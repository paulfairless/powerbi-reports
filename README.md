# Paginated Report Deployment with PowerShell and GitHub Actions

This repository contains a streamlined solution for deploying Power BI paginated reports (`.rdl` files) to different environments using PowerShell and GitHub Actions.

## Solution Overview

This solution uses a PowerShell script to interact with the Power BI REST API, providing a direct and focused way to manage your paginated reports.

The key features are:
-   **Environment-specific configurations:** Use JSON files to manage settings for your non-prod and prod environments.
-   **Automated deployment:** A PowerShell script handles the connection to Power BI, uploads reports, and configures their datasources.
-   **CI/CD Pipeline:** A GitHub Actions workflow automates the entire process, with separate jobs for non-prod and prod, including a manual approval step for production deployments.

### Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy-paginated-reports.yml
├── scripts/
│   └── Deploy-PaginatedReports.ps1
└── reports/
    ├── non-prod/
    │   └── config.json
    ├── prod/
    │   └── config.json
    └── rdl/
        └── SampleReport.rdl
```

## How to Use

1.  **Clone the repository.**

2.  **Add your `.rdl` files:**
    -   Place your paginated report files in the `reports/rdl` directory.

3.  **Configure your environments:**
    -   Update the `config.json` files in `reports/non-prod` and `reports/prod` with your Power BI workspace names and the connection details for your datasources.

4.  **Configure GitHub Secrets:**
    -   In your GitHub repository, go to `Settings > Secrets and variables > Actions`.
    -   Create the following secrets:
        -   `TENANT_ID`: The ID of your Azure AD tenant.
        -   `APP_ID_NON_PROD`: The Application (client) ID of the service principal for your non-prod environment.
        -   `APP_SECRET_NON_PROD`: The client secret for the non-prod service principal.
        -   `APP_ID_PROD`: The Application (client) ID of the service principal for your prod environment.
        -   `APP_SECRET_PROD`: The client secret for the prod service principal.
    -   Ensure that the service principals have the necessary permissions (e.g., `Workspace.ReadWrite.All`, `Report.ReadWrite.All`) in your Power BI tenants.

5.  **Push to `main`:**
    -   Push your changes to the `main` branch. The GitHub Actions workflow will automatically trigger, deploying your reports to the non-prod environment first, and then pausing for manual approval before deploying to production.

## PowerShell Script Details

The `scripts/Deploy-PaginatedReports.ps1` script is the core of this solution. It is designed to be run from the root of the repository and performs the following actions:
-   Installs the `MicrosoftPowerBIMgmt` module if it's not already present.
-   Connects to Power BI using the provided service principal credentials.
-   Reads the configuration for the specified environment.
-   Finds all `.rdl` files in the `reports/rdl` directory.
-   For each file, it uploads the report to the target workspace (overwriting if it exists).
-   It then configures the datasource for the report.

You can also run this script locally for testing purposes, provided you have PowerShell and the required module installed.
