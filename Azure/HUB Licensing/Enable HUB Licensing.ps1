Write-Host ""
Write-Host "ANS - Enable Azure HUB Licensing"
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

#Import CSV
$CSVPath = Read-Host "Please input the directory path to the CSV location"
$CSV = Import-Csv -Path $CSVPath"\Azure HUB Licensing.csv"

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


#Enable HUB Licensing
foreach ($VirtualMachine in $CSV) { 
    if($VirtualMachine."HUB Enabled" -ne 'True' -and $VirtualMachine.OSType -eq 'Windows') {
    Write-Output "Enabling HUB Licensing on" $VirtualMachine.VMName
    $VM = Get-AzureRMVm -ResourceGroupName $VirtualMachine.ResourceGroup -Name $VirtualMachine.VMName;
    $VM.LicenseType='Windows_Server'; 
    Update-AzureRmVM -ResourceGroupName $VM.ResourceGroupName -VM $VM
    Write-Output "HUB Licensing Enabled on" $VirtualMachine.VMName
    }
}