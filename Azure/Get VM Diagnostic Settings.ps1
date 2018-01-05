#Script to gather VM Diagnostics information for all VMs inside an Azure Subscription

#Parameters
$SubName = "<Subscription_Name>"
$FilePath = "<FilePath>.txt"

#Login to Azure
Login-AzureRmAccount

#Select Subscription
Select-AzureRMSubscription -SubscriptionName $SubName

#Get VM Diagnostic Information for all VMs
Write-Host "Gathering List of VMs with Diagnostics Enabled"
$Output = foreach ($VM in Get-AzureRmVM)
{
	Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name
}

#Save Output to CSV file
$Output | select ResourceGroupName, VMName, Name, Publisher, ProvisioningState | export-csv $FilePath
Write-Host "List of VMs with Diagnostics Enabled exported to CSV"