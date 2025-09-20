<#
.SYNOPSIS
Deploys paginated reports (.rdl files) to a Power BI workspace and configures their datasources.

.DESCRIPTION
This script automates the deployment of paginated reports to Power BI. It connects to Power BI using a service principal,
uploads the report files from a specified directory, and then configures the datasource for each report based on a
JSON configuration file.

.PARAMETER TenantId
The ID of the Azure tenant.

.PARAMETER AppId
The Application ID of the service principal.

.PARAMETER AppSecret
The secret of the service principal.

.PARAMETER Environment
The deployment environment (e.g., 'non-prod', 'prod'). This determines which configuration file to use.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$AppSecret,

    [Parameter(Mandatory = $true)]
    [string]$Environment
)

# Install the Power BI module if it's not already installed
if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing MicrosoftPowerBIMgmt module..."
    Install-Module -Name MicrosoftPowerBIMgmt -Force -AcceptLicense
}

# Connect to Power BI using the service principal
$credential = New-Object PSCredential($AppId, (ConvertTo-SecureString $AppSecret -AsPlainText -Force))
Connect-PowerBIServiceAccount -Tenant $TenantId -ServicePrincipal -Credential $credential

# Load environment configuration
$configFile = "reports/$Environment/config.json"
if (-not (Test-Path $configFile)) {
    Write-Error "Configuration file not found at $configFile"
    exit 1
}
$config = Get-Content $configFile | ConvertFrom-Json

$workspaceName = $config.workspaceName

# Get the workspace ID
try {
    $workspace = Get-PowerBIWorkspace -Name $workspaceName -ErrorAction Stop
}
catch {
    Write-Error "Failed to get workspace '$workspaceName'. Make sure it exists and the service principal has access."
    exit 1
}

$workspaceId = $workspace.Id

# Get all .rdl files
$reportFiles = Get-ChildItem -Path "reports/rdl" -Filter "*.rdl"

if ($reportFiles.Count -eq 0) {
    Write-Warning "No .rdl files found in the 'reports/rdl' directory."
    exit 0
}

foreach ($file in $reportFiles) {
    $reportName = $file.BaseName
    Write-Host "Deploying report '$reportName' from file $($file.FullName)..."

    # Upload the report
    try {
        $report = New-PowerBIReport -Path $file.FullName -WorkspaceId $workspaceId -DisplayName $reportName -ConflictAction Overwrite -ErrorAction Stop
        Write-Host "Successfully deployed report '$reportName'."
    }
    catch {
        Write-Error "Failed to deploy report '$reportName'. Error: $_"
        continue # Move to the next report
    }

    # Configure the datasource
    Write-Host "Configuring datasource for report '$reportName'..."
    try {
        $datasource = Get-PowerBIDatasource -ReportId $report.Id -WorkspaceId $workspaceId -ErrorAction Stop

        $connectionDetails = $config.datasource.connectionDetails
        $credentialDetails = New-Object Microsoft.PowerBI.Api.V2.Models.DatasourceCredentialDetails
        $credentialDetails.CredentialType = "None" # Using service principal for authentication

        Set-PowerBIDatasource -DatasourceId $datasource.DatasourceId -ReportId $report.Id -WorkspaceId $workspaceId -DatasourceDetails $connectionDetails -CredentialDetails $credentialDetails -ErrorAction Stop

        Write-Host "Successfully configured datasource for report '$reportName'."
    }
    catch {
        Write-Error "Failed to configure datasource for report '$reportName'. Error: $_"
    }
}

Write-Host "Deployment script finished."
