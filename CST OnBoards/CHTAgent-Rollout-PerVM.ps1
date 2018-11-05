Write-Output ""
Write-Output "ANS Azure CloudHealth Agent Install"
Write-Output "Version 4.0.0"
Write-Output ""
Write-Output ""


#Prompt for CloudHealth API Keys
$windowsapi = Read-Host "Please input the CloudHealth API Key for your Windows Servers"
$linuxapi = Read-Host "Please input the CloudHealth API Key for your Linux Servers"

#Create Windows OS Agent Install Script
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Windows Agent Install Script"
$content = '
#Create Temp Directory
New-Item -ItemType Directory -Path C:\Temp

#Download CloudHealth Agent
Invoke-WebRequest -OutFile C:\Temp\CloudHealthAgent.exe https://s3.amazonaws.com/remote-collector/agent/windows/18/CloudHealthAgent.exe

#Install CloudHealth Agent
C:\Temp\CloudHealthAgent.exe /S /v"/l* install.log /qn CLOUDNAME=azure CHTAPIKEY='+$windowsapi+'"
'
$content | Out-File './WindowsCloudHealthAgentInstall.ps1'
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Created Windows Agent Install Script Successfully"

#Create Linux OS Agent Install Script
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Linux Agent Install Script"
$content = '
#!/bin/bash
#Download CloudHealth Agent
wget https://s3.amazonaws.com/remote-collector/agent/v18/install_cht_perfmon.sh -O /tmp/install_cht_perfmon.sh;

#Install CloudHealth Agent
sudo sh /tmp/install_cht_perfmon.sh 18 '+$linuxapi+' azure;
'
$content | Out-File './LinuxCloudHealthAgentInstall.sh'
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Created Linux Agent Install Script Successfully"

#Import AzureRM Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AzureRM -ErrorVariable ModuleError -ErrorAction SilentlyContinue
if ($ModuleError) {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Module Error - $ModuleError"
Write-Output ""
}
else {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Output ""
}

#Login to Azure Environment
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Login-AzureRmAccount -ErrorVariable LoginError -ErrorAction SilentlyContinue
if ($LoginError) {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Login Error - $LoginError"
Write-Output ""
}
else {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Output ""
}

#Select SubscriptionId
$SubId = Read-Host "Please input your Subscription Id"
while ($SubId.Length -le 35) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $SubId = Read-Host "Please input your Subscription Id"
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Selecting Azure Subscripion"
Select-AzureRmSubscription -SubscriptionId $subId  -ErrorVariable SubscriptionError -ErrorAction SilentlyContinue
if ($SubscriptionError) {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Error - $SubscriptionError"
Write-Output ""
}
else {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Output ""
}


#Custom Parameters
$resourceGroup =  Read-Host "Please input the Resource Group Name for the Virtual Machine to install the Agent on"
$vmName =  Read-Host "Please input VM Name for the Virtual Machine to install the Agent on"

#Static Parameters
$StorageAccount = "cloudhealthagent"
$Container = "scripts"
$FileUrlWindows = "https://cloudhealthagent.blob.core.windows.net/scripts/WindowsCloudHealthAgentInstall.ps1"
$FileNameWindows = "WindowsCloudHealthAgentInstall.ps1"
$ExtensionName = "CloudHealthExtension"
$StorageAccountKey = "e0jRGGgXyZah3qxFwEDgPEdkK/juxK2rcRXYK1gE966ukQhbPbcDjHtDm1/MHQ5+1JLf5mAqUJBb/zjI0PTegw=="
$ProtectedSettings = '{"storageAccountName":"' + $StorageAccount + '","storageAccountKey":"' + $StorageAccountKey + '"}';
$Settings = '{
    "fileUris": ["https://cloudhealthagent.blob.core.windows.net/scripts/LinuxCloudHealthAgentInstall.sh"], 
    "commandToExecute": "sh LinuxCloudHealthAgentInstall.sh"
}';

#Create Storage Context
$Context = New-AzureStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccountKey

#Upload Windows OS Agent Install Script to Storage Account
Get-AzureStorageBlob -Container $Container -Blob 'WindowsCloudHealthAgentInstall.ps1' -Context $Context.Context | Set-AzureStorageBlobContent -File 'WindowsCloudHealthAgentInstall.ps1' -Force

#Upload Linux OS Agent Install Script to Storage Account
Get-AzureStorageBlob -Container $Container -Blob 'LinuxCloudHealthAgentInstall.sh' -Context $Context.Context | Set-AzureStorageBlobContent -File 'LinuxCloudHealthAgentInstall.sh' -Force

#Get VM
$VM = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName

if ($VM.StorageProfile.OsDisk.OsType -eq 'Windows'){
    Write-Output ("Setting extension on VM " + $VM.Name)
	Set-AzureRmVMCustomScriptExtension -Name $ExtensionName -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name -Location $VM.Location -FileUri $FileUrlWindows -Run $FileNameWindows
}
if ($VM.StorageProfile.OsDisk.OsType -eq 'Linux'){
    Write-Output ("Setting extension on VM " + $VM.Name)
    Set-AzureRmVMExtension -Name $ExtensionName -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name -Location $VM.Location -Publisher "Microsoft.OSTCExtensions" -ExtensionType  "CustomScriptForLinux" -TypeHandlerVersion "1.5" -Settingstring $Settings -ProtectedSettingString $ProtectedSettings
}

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] VM Extension has been added successfully"
