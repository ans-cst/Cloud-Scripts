Write-Host ""
Write-Host "ANS Convert Azure VM to Managed Disks"
Write-Host "Version 1.0.0"
Write-Host ""
Write-Host ""

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

#Set Environment Variables
$vmName = Read-Host "Please Input the Virtual Machines Name"
$rgName = Read-Host "Please Input the Virtual Machines Resource Group Name"


#Login to Azure Environment
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Login-AzureRmAccount
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Host ""

#Set Subscription Id
$SubId = Read-Host "Please input your Subscription Id"
while ($SubId.Length -le 35) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $SubId = Read-Host "Please input your Subscription Id"
}
Select-AzureRmSubscription -SubscriptionId $SubId
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Host ""

#Stop Virtual Machine
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Virtual Machine" $vmName
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force

$VMState = Get-AzureRmVm -ResourceGroupName $rgName -Name $vmName -Status
while ($VMState.Statuses.DisplayStatus[1] -ne "VM deallocated") {
    Write-Host "Check the status of" $vmName
    SLEEP 2
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $vmName "has successfully stopped"

#Convert VM to Managed Disks
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converting Virtual Machine" $vmName "to managed disks"
ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vmName
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converted Virtual Machine" $vmName "to managed disks successfully!"
