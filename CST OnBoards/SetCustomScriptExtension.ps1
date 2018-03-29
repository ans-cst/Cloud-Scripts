Write-Host ""
Write-Host "ANS Azure CloudHealth Agent Install"
Write-Host "Version 4.0.0"
Write-Host ""
Write-Host ""


#Prompt for CloudHealth API Keys
$windowsapi = Read-Host "Please input the CloudHealth API Key for your Windows Servers"
$linuxapi = Read-Host "Please input the CloudHealth API Key for your Linux Servers"

#Create Windows OS Agent Install Script
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Windows Agent Install Script <br />"
$content = '
#Create Temp Directory
New-Item -ItemType Directory -Path C:\Temp

#Download CloudHealth Agent
Invoke-WebRequest -OutFile C:\Temp\CloudHealthAgent.exe https://s3.amazonaws.com/remote-collector/agent/windows/18/CloudHealthAgent.exe

#Install CloudHealth Agent
C:\Temp\CloudHealthAgent.exe /S /v"/l* install.log /qn CLOUDNAME=azure CHTAPIKEY='+$windowsapi+'"
'
$content | Out-File './WindowsCloudHealthAgentInstall.ps1'
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Created Windows Agent Install Script Successfully <br />"

#Create Linux OS Agent Install Script
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Linux Agent Install Script <br />"
$content = '
#!/bin/bash
#Download CloudHealth Agent
wget https://s3.amazonaws.com/remote-collector/agent/v18/install_cht_perfmon.sh -O /tmp/install_cht_perfmon.sh;

#Install CloudHealth Agent
sudo sh /tmp/install_cht_perfmon.sh 18 '+$linuxapi+' azure;
'
$content | Out-File './LinuxCloudHealthAgentInstall.sh'
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Created Linux Agent Install Script Successfully <br />"

#Import AzureRM Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AzureRM -ErrorVariable ModuleError -ErrorAction SilentlyContinue
if ($ModuleError) {
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Module Error - $ModuleError"
Write-Host ""
}
else {
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""
}

#Login to Azure Environment
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Login-AzureRmAccount -ErrorVariable LoginError -ErrorAction SilentlyContinue
if ($LoginError) {
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Login Error - $LoginError"
Write-Host ""
}
else {
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Host ""
}

#Select SubscriptionId
$SubId = Read-Host "Please input your Subscription Id"
while ($SubId.Length -le 35) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $SubId = Read-Host "Please input your Subscription Id"
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Selecting Azure Subscripion"
Select-AzureRmSubscription -SubscriptionId $subId  -ErrorVariable SubscriptionError -ErrorAction SilentlyContinue
if ($SubscriptionError) {
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Error - $SubscriptionError"
Write-Host ""
}
else {
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Host ""
}


#Custom Parameters
$resourceGroup =  Read-Host "Please input the Resource Group Name for the Virtual Machines to install the Agent on"

#Static Parameters
$StorageAccount = "cloudhealthagent"
$Container = "scripts"
$FileUrlWindows = "https://cloudhealthagent.blob.core.windows.net/scripts/WindowsCloudHealthAgentInstall.ps1"
$FileNameWindows = "WindowsCloudHealthAgentInstall.ps1"
$ExtensionName = "CloudHealthExtension"
$StorageAccountKey = "YfOaZDO2kdiMzHNxTiBpdTuJwM6/ZYT+m6V3K43n8N3yxclC14y2rcUegqGZdDMYDLexEvGQk9qZ8wYfzksUNA=="
$ProtectedSettings = '{"storageAccountName":"' + $StorageAccount + '","storageAccountKey":"' + $StorageAccountKey + '"}';
$Settings = '{
    "fileUris": ["https://cloudhealthtesting.blob.core.windows.net/agentinstall/LinuxCloudHealthAgentInstall.sh"], 
    "commandToExecute": "sh LinuxCloudHealthAgentInstall.sh"
}';

#Create Storage Context
$Context = New-AzureStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccountKey

#Upload Windows OS Agent Install Script to Storage Account
Get-AzureStorageBlob -Container $Container -Blob 'WindowsCloudHealthAgentInstall.ps1' -Context $Context.Context | Set-AzureStorageBlobContent -File 'WindowsCloudHealthAgentInstall.ps1' -Force

#Upload Linux OS Agent Install Script to Storage Account
Get-AzureStorageBlob -Container $Container -Blob 'LinuxCloudHealthAgentInstall.sh' -Context $Context.Context | Set-AzureStorageBlobContent -File 'LinuxCloudHealthAgentInstall.sh' -Force

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

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] VM Extensions have been added successfully <br />"