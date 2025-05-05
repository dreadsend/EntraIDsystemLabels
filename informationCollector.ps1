<#
.SYNOPSIS
  Gives a Report of all systemLabels Values in a Tenant
.DESCRIPTION
  The Script will connect to the Graph API in the manner specified and fetch the Information of all Devices that have a systemLabel set
  A large block of Connect-MgGraph Parameters are Mirrored

.PARAMETER useSecret
  Switch to prompt for a Secret in Combination with tenantId and clientId instad of a certificate Thumbprint

.PARAMETER fullList
  Returns the full list of the Devices instead of simplifying

.NOTES
  Version:        1.1
  Author:         Julian Sperling
  Creation Date:  09.12.23
  Last Updated: 05.05.25
  Purpose/Change: Minor Code Optimizations
#>

#Requires -modules Microsoft.Graph.Authentication

param(
    [Parameter(ParameterSetName = "Interactive")]

    [Parameter(ParameterSetName = "CustomApp", Mandatory = $true)]
    [Parameter(ParameterSetName = "ClientCert", Mandatory = $true)]
    [Parameter(ParameterSetName = "ClientCredentials", Mandatory = $true)]
    [string]$tenantId,

    [Parameter(ParameterSetName = "CustomApp", Mandatory = $true)]
    [Parameter(ParameterSetName = "ClientCert", Mandatory = $true)]
    [Parameter(ParameterSetName = "ClientCredentials", Mandatory = $true)]
    [string]$clientId,

    [Parameter(ParameterSetName = "ClientCert", Mandatory = $true)]
    [ValidateNotNull()]
    [string]$certificateThumbprint,

    [Parameter(ParameterSetName = "ClientCredentials", Mandatory = $true)]
    [switch]$useSecret,

    [Parameter(ParameterSetName = "DeviceCode", Mandatory = $true)]
    [switch]$deviceCode,

    [switch]$fullList

)

$requiredScopes = @('Device.Read.All')

$deviceProperties = @('displayName', 'systemLabels')

# ArrayList is a reference type, so the base object is always modified, no return necessary
function Get-GraphData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [hashtable]$headers = @{},

        [System.Collections.Arraylist]$result
    )

    # Get the first set of Devices from the Graph API and store them
    $response = Invoke-MgGraphRequest -Method GET -Uri $Uri -Headers $headers -OutputType PSObject
    $result.AddRange($response.value)

    # Check for the next link and recursively fetch data
    if ($response.'@odata.nextLink') {
        Get-GraphData -Uri $response.'@odata.nextLink' -headers $headers -result $result
    }
}

# Connect to Graph API depending on Script Parameters Used
switch ($PSCmdlet.ParameterSetName) {
    "Interactive" {
        Connect-MgGraph -Scopes $requiredScopes -NoWelcome
    }
    "ClientCert" {
        Connect-MgGraph -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $certificateThumbprint -NoWelcome
    }
    "ClientCredentials" {
        $ClientSecretCredential = Get-Credential -Credential $clientId
        Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
    }
    "DeviceCode" {
        Connect-MgGraph -Scopes $requiredScopes -UseDeviceAuthentication -NoWelcome
    }
    "CustomApp" {
        Connect-MgGraph -TenantId $tenantId -ClientId $clientId -NoWelcome
    }
}


# Check if all required Scopes are Present
$missingScopes = $requiredScopes | Where-Object { $_ -notin $(Get-MgContext).Scopes }
if ($missingScopes) {
    Write-Host "The following Scopes are missing: $($missingScopes -join ', ')"
    Write-Host "Please elevate to a Device / Global Reader Entra ID Role or add the Scope(s) to your Enterprise App and consent."
    return
}

$devices = [System.Collections.Arraylist]::new()

# It feels wrong to me to fetch all Devices and start processing them locally if the API Supports Filters that give us what we want
# We have to tell the Graph API that we are using count ($count=true) and accept a lower consistency Level
$uri = 'https://graph.microsoft.com/v1.0/devices?$filter=systemLabels/$count ne 0&$count=true&$select={0}' -f $($deviceProperties -join ',')
Get-GraphData -Uri $uri -result $devices -headers @{ ConsistencyLevel = "eventual" }

# If the Full list was requested we skip the simplification
if ($fullList) {return $devices}


$result = @{}
# For simplicity and speed I only store one example for each value
foreach ($dev in $devices){
    foreach ($entry in $dev.systemLabels){
        $result.$entry = $($dev.displayName)
    } 
}

Write-Host ("These are the System Labels in your environment with the Displayname of an example device")
Write-Host ("If you want the full list use the -fullList Parameter of the script")
Write-Host ("Please check if there is an unkdocumented value. Let me know what the value is and what you presume it might be used for ;)")
$result.Keys | Select-Object @{Name = "systemLabel"; Expression = {$_} }, @{Name = "Example"; Expression = {$result.$_} } | Format-Table -AutoSize

Read-Host
