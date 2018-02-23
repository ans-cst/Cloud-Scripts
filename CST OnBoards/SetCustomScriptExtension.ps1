Write-Host ""
Write-Host "ANS Azure CloudHealth Agent Install"
Write-Host "Version 3.0.0"
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


#Custom Parameters
$resourceGroup =  "" #resourceGroup name that contains the VMs to install the agent.

#Static Parameters
$StorageAccount = "cloudhealthtesting"
$Container = "agentinstall"
$FileUrlWindows = "https://cloudhealthtesting.blob.core.windows.net/agentinstall/WindowsCloudHealthAgentInstall.ps1"
$FileNameWindows = "WindowsCloudHealthAgentInstall.ps1"
$ExtensionName = "CloudHealthExtension"
$StorageAccountKey = "qkRrIkUraoLXBr4/LcD6ShSfG7RP4imIZ/XbT37Y0c5ubJYnVSnpM8zn5bvc1y+jFoyTejenzzx2I7EnqlV8og=="
$ProtectedSettings = '{"storageAccountName":"' + $StorageAccount + '","storageAccountKey":"' + $StorageAccountKey + '"}';
$Settings = '{
    "fileUris": ["https://cloudhealthtesting.blob.core.windows.net/agentinstall/LinuxCloudHealthAgentInstall.sh"], 
    "commandToExecute": "sh LinuxCloudHealthAgentInstall.sh"
}';


#GatherVMs
$VMs = Get-AzureRmVM -ResourceGroupName $resourceGroup
$vmOutput = @()
$VMs | ForEach-Object {
$tmpObj = New-Object -TypeName PSObject
$tmpObj | Add-Member -MemberType Noteproperty -Name "VMName" -Value $_.Name
$tmpObj | Add-Member -MemberType Noteproperty -Name "OStype" -Value $_.StorageProfile.OsDisk.OsType
$tmpObj | Add-Member -MemberType Noteproperty -Name "VMResourceGroup" -Value $_.ResourceGroupName
$tmpObj | Add-Member -MemberType Noteproperty -Name "Location" -Value $_.location
$vmOutput += $tmpObj
}
$vmoutput

#Filter Windows VMs
$WindowsVM = $vmoutput | where 'OStype' -eq "Windows"

#Filter Linux VMs
$LinuxVM = $vmoutput | where 'OStype' -eq "Linux"

#Add Custom Script Extension to Windows VMs
foreach ($VM in $WindowsVM)
{
	$resourceGroup = $VM.VMResourceGroup
	$VMName = $VM.VMName
    $location = $VM.Location
    Write-Host "Setting extension on VM " $vmname
	Set-AzureRmVMCustomScriptExtension -Name $ExtensionName -ResourceGroupName $resourceGroup -VMName $VMName -Location $location -FileUri $FileUrlWindows -Run $FileNameWindows
}

#Add Custom Script Extension to Linux VMs
foreach ($VM in $LinuxVM)
{
	$resourceGroup = $VM.VMResourceGroup
	$VMName = $VM.VMName
    $location = $VM.Location
    Write-Host "Setting extension on VM " $vmname
    Set-AzureRmVMExtension -Name $ExtensionName -ResourceGroupName $resourceGroup -VMName $VMName -Location $location -Publisher "Microsoft.OSTCExtensions" -ExtensionType  "CustomScriptForLinux" -TypeHandlerVersion "1.5" -Settingstring $Settings -ProtectedSettingString $ProtectedSettings
}
