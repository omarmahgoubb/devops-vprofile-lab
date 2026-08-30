# Lists the region of every resource in one Azure resource group.
# Usage:
#   .\Show-ResourceGroupRegions.ps1
#   .\Show-ResourceGroupRegions.ps1 -ResourceGroupName INCODED_RG_2026

param(
    [string]$ResourceGroupName
)

function Show-GroupResources {
    param([string]$Name)

    $groupJson = az group show --name $Name -o json 2>$null
    if (-not $groupJson) {
        Write-Host "Resource group '$Name' was not found." -ForegroundColor Red
        return
    }

    $group = $groupJson | ConvertFrom-Json
    Write-Host "Resource group: $($group.name)" -ForegroundColor Cyan
    Write-Host "Resource group metadata region: $($group.location)"
    Write-Host "(The group region is only metadata. Each resource can sit in a different region.)"
    Write-Host ""

    az resource list `
        --resource-group $Name `
        --query "[].{Name:name, Type:type, Region:location}" `
        -o table
    Write-Host ""
}

az account show --query "{Subscription:name, User:user.name}" -o table
Write-Host ""

if ($ResourceGroupName) {
    Show-GroupResources -Name $ResourceGroupName
    return
}

Write-Host "No resource group given. Existing groups:" -ForegroundColor Cyan
az group list --query "[].{Name:name, Region:location}" -o table
Write-Host ""

$groups = az group list --query "[].name" -o tsv
foreach ($name in $groups) {
    Show-GroupResources -Name $name
}
