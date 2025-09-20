<#
.SYNOPSIS
Deploys paginated reports (.rdl files) to a Power BI workspace and configures their datasources for a specific customer.

.DESCRIPTION
This script automates the deployment of paginated reports to Power BI. It connects to Power BI using a main service principal,
and then uses a customer-specific service principal (defined in the config) for the datasource credentials.

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
$configFile = "reports/$CustomerName/$Environment/config.json"
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

        $dsConfig = $config.datasource
        $connectionDetails = $dsConfig.connectionDetails

        # Get the datasource credential details from the config
        $credConfig = $dsConfig.credentialDetails
        $dsAppId = $env:($credConfig.appIdSecretName)
        $dsAppSecret = $env:($cred_config.appSecretSecretName)

        if ([string]::IsNullOrEmpty($dsAppId) -or [string]::IsNullOrEmpty($dsAppSecret)) {
            throw "Datasource service principal credentials not found in environment variables. Make sure secrets are mapped correctly in the GitHub Actions workflow."
        }

        # Create the credential object for the datasource
        $datasourceCredentials = [Microsoft.PowerBI.Api.V2.Models.CredentialDetails]::new(
            (
                [Microsoft.PowerBI.Api.V2.Models.ServicePrincipalCredentials]::new(
                    $dsAppId,
                    $dsAppSecret
                )
            ),
            "ServicePrincipal",
            "ReadWrite"
        )

        Set-PowerBIDatasource -DatasourceId $datasource.DatasourceId -ReportId $report.Id -WorkspaceId $workspaceId -DatasourceDetails $connectionDetails -CredentialDetails $datasourceCredentials -ErrorAction Stop

        Write-Host "Successfully configured datasource for report '$reportName'."
    }
    catch {
        Write-Error "Failed to configure datasource for report '$reportName'. Error: $_"
    }
}

Write-Host "Deployment script finished."
