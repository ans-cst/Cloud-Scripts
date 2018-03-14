Write-Host ""
Write-Host "ANS Convert Azure Availabiltiy Set to Managed Disks"
Write-Host "Version 1.2.0"
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
$avSetName = Read-Host "Please input the Availability Set Name"
$rgName = Read-Host "Please input the Virtual Machines Resource Group Name"
[uint16]$Time = Read-Host "Please input the amount of time to wait between converting each VM in seconds"

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

#Convert Availability set to Managed
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Changing Availability set SKU to aligned"

#Try with current number of fault domains
$avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avSetName
Update-AzureRmAvailabilitySet -AvailabilitySet $avSet -Sku Aligned -ErrorAction SilentlyContinue

#If Error Try with 2 Fault Domains
if ($error.Count -gt 0) {
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Changing Availability set Fault Domains to 2 as current number is not supported"
$avSet.PlatformFaultDomainCount = 2
Update-AzureRmAvailabilitySet -AvailabilitySet $avSet -Sku Aligned  
}

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Availability set updated successfully"

#Convert each VM disks to managed
$avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avSetName
foreach($vm in $avSet.VirtualMachinesReferences)
{
  #Get VM Object  
  $vm = Get-AzureRmResource -ResourceId $vm.id

  #Stop VM
  Write-Host ""
  Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping Virtual Machine -" $vm.Name
  Stop-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name -Force

  #Convert VM to Managed Disks
  Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converting" $vm.Name "to Managed Disks"
  ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vm.Name
  Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converted" $vm.Name "to Managed Disks successfully"

  #Start VM
  Start-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name
  Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Virtual Machine" $vm.Name "started successfully"

  #Wait for specified time period before proceeding
  Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting for previous VM to boot and start application services - waiting for" $Time "seconds"
  SLEEP $TIME
}