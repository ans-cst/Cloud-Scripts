#Set Environment Variables
$rgName = "Test"
$vmName = "Windows-Test"

#Login to Azure Environment
Login-AzureRmAccount

#Set Subscription Id
Select-AzureRmSubsciptionId -SubscriptionId 

#Convert VM to Managed Disks
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force
ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vmName