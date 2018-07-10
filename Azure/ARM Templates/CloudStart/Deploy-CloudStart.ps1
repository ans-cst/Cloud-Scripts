<#
    .DESCRIPTION
        PS Script to Deploy Imperial CloudStart Environment.

    .NOTES
        AUTHOR: ANS - Ryan Froggatt
        LASTEDIT: July 20, 2018
#>

#Install and Import AzureRM Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AzureRM -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AzureRM
    Import-Module -Name AzureRM
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""

#Login to Azure
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Login-AzureRmAccount
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Host ""

#Select SubscriptionId
$SubId = Read-Host "Please input your Subscription Id"
while ($SubId.Length -le 35) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $SubId = Read-Host "Please input your Subscription Id"
}
Select-AzureRmSubscription -SubscriptionId $SubId
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Host ""

#Configure Azure Location to Deploy CloudStart
$Location = Read-Host "Enter the location to deploy the CloudStart"

# Create Required Resource Groups
New-AzureRmResourceGroup -Name RG-WE-ARM-DEPLOYMENTS -Location "West Europe"

# Deploy Core Networking Resources
New-AzureRmResourceGroupDeployment -ResourceGroupName RG-WE-ARM-DEPLOYMENTS -TemplateUri 'https://raw.githubusercontent.com/ans-cst/Cloud-Scripts/master/Azure/ARM%20Templates/CloudStart/Networking-Master-CloudStart.json' `
-TemplateParameterUri 'https://raw.githubusercontent.com/ans-cst/Cloud-Scripts/master/Azure/ARM%20Templates/CloudStart/Networking-Master-Parameters-CloudStart.json'