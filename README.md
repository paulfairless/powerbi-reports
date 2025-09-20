# Power BI Report Deployment with Terraform and GitHub Actions

This repository contains a solution for deploying Power BI reports to different environments (non-prod and prod) using Terraform and GitHub Actions.

## Solution Overview

The solution uses a modular Terraform configuration to manage Power BI reports. It is designed to support:
-   Multiple environments (e.g., non-prod, prod).
-   Common and bespoke reports.
-   Assignment of a service principal for data connectivity.

A GitHub Actions workflow automates the deployment process.

### Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml
├── terraform/
│   ├── modules/
│   │   └── powerbi_report/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── environments/
│   │   ├── non-prod/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── terraform.tfvars
│   │   └── prod/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── terraform.tfvars
│   └── reports/
│       ├── common/
│       │   └── report1.pbix
│       └── customerA/
│           └── bespoke_report.pbix
└── README.md
```

## How to Use

1.  **Clone the repository.**

2.  **Configure Terraform Variables:**
    -   Update the `terraform.tfvars` files in `terraform/environments/non-prod` and `terraform/environments/prod` with your specific tenant IDs, subscription IDs, Power BI workspace IDs, and database connection details.

3.  **Configure GitHub Secrets:**
    -   In your GitHub repository, go to `Settings > Secrets and variables > Actions`.
    -   Create the following secrets for both your non-prod and prod environments:
        -   `ARM_CLIENT_ID_NON_PROD`, `ARM_CLIENT_SECRET_NON_PROD`, `ARM_SUBSCRIPTION_ID_NON_PROD`, `ARM_TENANT_ID_NON_PROD`
        -   `ARM_CLIENT_ID_PROD`, `ARM_CLIENT_SECRET_PROD`, `ARM_SUBSCRIPTION_ID_PROD`, `ARM_TENANT_ID_PROD`
    -   These secrets should contain the credentials for a service principal that has permissions to create resources in your Azure subscription and manage Power BI.

4.  **Add your `.pbix` files:**
    -   Place your common and bespoke `.pbix` report files in the `terraform/reports` directory, following the existing structure.
    -   Update the `main.tf` files in the `terraform/environments` directories to point to your new reports.

5.  **Push to `main`:**
    -   Push your changes to the `main` branch to trigger the GitHub Actions workflow.

## Important Notes

### Power BI Deployment Placeholder

The Terraform module `powerbi_report` uses a `null_resource` with a `local-exec` provisioner as a placeholder for the actual deployment of the Power BI reports. This is because there is no official HashiCorp Terraform provider for Power BI.

**To implement the actual deployment, you will need to:**
1.  Create a script (e.g., PowerShell, Python) that uses the Power BI REST API to upload the `.pbix` files.
2.  Modify the `main.tf` file in the `powerbi_report` module to execute your script. You can find guidance and examples in the comments within that file.

### GitHub Actions Environments

The GitHub Actions workflow uses environments (`non-prod` and `prod`). You may need to configure these in your repository settings (`Settings > Environments`) to add protection rules, such as manual approval for the production environment. The provided workflow is a basic template and can be customized to fit your specific needs.
