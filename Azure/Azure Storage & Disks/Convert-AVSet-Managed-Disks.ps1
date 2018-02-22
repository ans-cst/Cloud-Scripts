#Set Environment Variables
$rgName = ""
$avSetName = ""
$subscriptionId = ""

#Login to Azure Environment
Login-AzureRmAccount

#Set Subscription Id
Select-AzureRmSubscription -SubscriptionId 

#Convert Availability set to Managed
$avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avSetName
Update-AzureRmAvailabilitySet -AvailabilitySet $avSet -Sku Aligned 

#Convert VM disks to managed
$avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avSetName
foreach($vmInfo in $avSet.VirtualMachinesReferences)
{
  $vm = Get-AzureRmVM -ResourceGroupName $rgName | Where-Object {$_.Id -eq $vmInfo.id}
  Stop-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name -Force
  ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vm.Name
}