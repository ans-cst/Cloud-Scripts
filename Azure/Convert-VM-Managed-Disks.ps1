#Set Environment Variables
$rgName = "POC"
$vmName = "Test-Linux"
$SubscriptionId = ""

#Login to Azure Environment
Login-AzureRmAccount

#Set Subscription Id
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

#Convert VM to Managed Disks
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force
ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vmName