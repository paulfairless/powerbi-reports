# Paginated Report Deployment with PowerShell and GitHub Actions

This repository contains a flexible solution for deploying Power BI paginated reports (`.rdl` files) to multiple customers and environments using PowerShell and GitHub Actions.

## Solution Overview

This solution is designed for multi-tenant deployments where each customer has their own Power BI workspace and their own service principal for database access.

The key features are:
-   **Customer-centric configuration:** A directory structure organized by customer, making it easy to manage settings for each one.
-   **Interactive deployment:** A GitHub Actions workflow that allows you to select which customer and which environment (`non-prod` or `prod`) you want to deploy to.
-   **Dynamic PowerShell script:** A single script that handles the deployment logic for any customer and environment.
-   **Secure credential management:** Uses GitHub secrets with a clear naming convention to manage credentials for both the main Power BI connection and customer-specific datasources.

### Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy-paginated-reports.yml
├── scripts/
│   └── Deploy-PaginatedReports.ps1
└── reports/
    ├── customerA/
    │   ├── non-prod/
    │   │   └── config.json
    │   └── prod/
    │       └── config.json
    ├── customerB/
    │   # ... same structure as customerA
    └── rdl/
        └── SampleReport.rdl
```

## How to Use

### 1. Add your Reports
-   Place your common `.rdl` files in the `reports/rdl` directory.

### 2. Add and Configure a New Customer
1.  **Create a directory** for your customer inside the `reports` folder (e.g., `reports/customerC`).
2.  Inside the customer folder, create `non-prod` and `prod` subfolders.
3.  **Add `config.json` files** to the `non-prod` and `prod` folders. Copy the structure from an existing customer and update the values for the new customer's workspace name and database details.
4.  **Update the GitHub Actions workflow** (`.github/workflows/deploy-paginated-reports.yml`): Add the new customer's name to the `options` list under `inputs.customer`.

### 3. Configure GitHub Secrets
-   In your GitHub repository, go to `Settings > Secrets and variables > Actions`.
-   Add the following secrets. The workflow uses a naming convention to find the correct secret for each customer and environment.

    **Main Service Principal (for connecting to Power BI):**
    -   `TENANT_ID`: The ID of your Azure AD tenant.
    -   `APP_ID_NON_PROD`: The App ID of the service principal for your non-prod environment.
    -   `APP_SECRET_NON_PROD`: The secret for the non-prod service principal.
    -   `APP_ID_PROD`: The App ID of the service principal for your prod environment.
    -   `APP_SECRET_PROD`: The secret for the prod service principal.

    **Datasource Service Principals (for each customer):**
    -   Follow this pattern: `DATASOURCE_SP_APP_ID_<CUSTOMER_NAME>_<ENVIRONMENT>`
    -   Example for `customerA`, `non-prod`:
        -   `DATASOURCE_SP_APP_ID_CUSTOMERA_NON_PROD`
        -   `DATASOURCE_SP_APP_SECRET_CUSTOMERA_NON_PROD`
    -   Example for `customerA`, `prod`:
        -   `DATASOURCE_SP_APP_ID_CUSTOMERA_PROD`
        -   `DATASOURCE_SP_APP_SECRET_CUSTOMERA_PROD`

### 4. Run the Deployment
1.  Go to the **Actions** tab in your GitHub repository.
2.  In the left sidebar, click on the **Deploy Paginated Reports** workflow.
3.  Click the **Run workflow** dropdown button on the right.
4.  Select the **customer** and **environment** you want to deploy to.
5.  Click the **Run workflow** button to start the deployment.
