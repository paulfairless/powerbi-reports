<#
.SYNOPSIS
Deploys Power BI reports (.pbix and .rdl) to a Power BI workspace and configures their datasources.

.DESCRIPTION
This script automates the deployment of all Power BI reports. It connects to Power BI using a main service principal,
and then uses a customer-specific service principal (defined in the config) for the datasource credentials.
It handles both standard (.pbix) and paginated (.rdl) reports.

.PARAMETER TenantId
The ID of the Azure tenant for the main Power BI connection.

.PARAMETER AppId
The Application ID of the main service principal used to connect to Power BI.

.PARAMETER AppSecret
The secret of the main service principal.

.PARAMETER CustomerName
The name of the customer to deploy for. This corresponds to a folder in the 'reports' directory.

.PARAMETER Environment
The deployment environment (e.g., 'non-prod', 'prod').
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$AppSecret,

    [Parameter(Mandatory = $true)]
    [string]$CustomerName,

    [Parameter(Mandatory = $true)]
    [string]$Environment

    [Parameter(Mandatory = $true)]
    [string]$SpId

    [Parameter(Mandatory = $true)]
    [string]$SpSecret
)

# Install the Power BI module if it's not already installed
if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing MicrosoftPowerBIMgmt module..."
    Install-Module -Name MicrosoftPowerBIMgmt -Force -AcceptLicense
}

# Connect to Power BI using the main service principal
Write-Host "Connecting to Power BI..."
$credential = New-Object PSCredential($AppId, (ConvertTo-SecureString $AppSecret -AsPlainText -Force))
Connect-PowerBIServiceAccount -Tenant $TenantId -ServicePrincipal -Credential $credential

# Load customer and environment specific configuration
$configFile = "reports/$Environment/$CustomerName/config.json"
Write-Host "Loading configuration from $configFile..."
if (-not (Test-Path $configFile)) {
    Write-Error "Configuration file not found at $configFile"
    exit 1
}
$config = Get-Content $configFile | ConvertFrom-Json

$workspaceName = $config.workspaceName

# Get the workspace ID
Write-Host "Getting workspace ID for '$workspaceName'..."
try {
    $workspace = Get-PowerBIWorkspace -Name $workspaceName -ErrorAction Stop
}
catch {
    Write-Error "Failed to get workspace '$workspaceName'. Make sure it exists and the service principal has access."
    exit 1
}
$workspaceId = $workspace.Id

# Get all report files (.rdl and .pbix)
$reportFiles = Get-ChildItem -Path "reports/standard", -Recurse -Include "*.rdl", "*.pbix"

if ($reportFiles.Count -eq 0) {
    Write-Warning "No report files found in 'reports/rdl' or 'reports/pbix'."
    exit 0
}

# --- Datasource Configuration Details ---
$dsConfig = $config.datasource
$connectionDetails = $dsConfig.connectionDetails
$credConfig = $dsConfig.credentialDetails

$datasourceCredentials = [Microsoft.PowerBI.Api.V2.Models.CredentialDetails]::new(
    (
        [Microsoft.PowerBI.Api.V2.Models.ServicePrincipalCredentials]::new(
            $SpId,
            $SpSecret
        )
    ),
    "ServicePrincipal",
    "ReadWrite"
)

# --- Process each report ---
foreach ($file in $reportFiles) {
    $reportName = $file.BaseName
    Write-Host "--- Deploying report '$reportName' from file $($file.FullName)... ---"

    # Upload the report
    try {
        $report = New-PowerBIReport -Path $file.FullName -WorkspaceId $workspaceId -DisplayName $reportName -ConflictAction Overwrite -ErrorAction Stop
        Write-Host "Successfully deployed report '$reportName'."
    }
    catch {
        Write-Error "Failed to deploy report '$reportName'. Error: $_"
        continue # Move to the next report
    }

    # Configure the datasource based on report type
    Write-Host "Configuring datasource for '$reportName'..."
    try {
        if ($file.Extension -eq ".rdl") {
            # This is a paginated report
            $datasource = Get-PowerBIDatasource -ReportId $report.Id -WorkspaceId $workspaceId -ErrorAction Stop
            Set-PowerBIDatasource -DatasourceId $datasource.DatasourceId -ReportId $report.Id -WorkspaceId $workspaceId -DatasourceDetails $connectionDetails -CredentialDetails $datasourceCredentials -ErrorAction Stop
        }
        elseif ($file.Extension -eq ".pbix") {
            # This is a standard Power BI report, so we need to configure the dataset
            $dataset = Get-PowerBIDataset -WorkspaceId $workspaceId -Name $report.Name -ErrorAction Stop
            $datasource = Get-PowerBIDatasource -DatasetId $dataset.Id -WorkspaceId $workspaceId -ErrorAction Stop
            Set-PowerBIDatasource -DatasourceId $datasource.DatasourceId -DatasetId $dataset.Id -WorkspaceId $workspaceId -DatasourceDetails $connectionDetails -CredentialDetails $datasourceCredentials -ErrorAction Stop

            # Also update the dataset itself to use the service principal
            Set-PowerBIDataset -Id $dataset.Id -WorkspaceId $workspaceId -DefaultMode "Push" -DefaultRetentionPolicy "None" -ErrorAction Stop
        }
        Write-Host "Successfully configured datasource for '$reportName'."
    }
    catch {
        Write-Error "Failed to configure datasource for report '$reportName'. Error: $_"
    }
}

Write-Host "Deployment script finished."
