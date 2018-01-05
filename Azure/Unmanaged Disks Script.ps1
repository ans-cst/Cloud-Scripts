#Login to Azure ARM Account
Login-AzureRmAccount

#Select Subscription
Select-AzureRmSubscription -SubscriptionId <Replace with SubscriptionId>

#Create HashTable
$AGSet=@{}; 


#Get Availability Sets
foreach ($RG in Get-AzureRmResourceGroup) {foreach ($AVSets in Get-AzureRmAvailabilitySet -ResourceGroupName $RG.ResourceGroupName) 
  {
  $TXT= ""+$AVSets.Managed+'|'+$AVSets.Location+'|'+$AVSets.PlatformFaultDomainCount+'|'+$AVSets.PlatformUpdateDomainCount

  Write-Output($AVSets.Name+" - "+$TXT)
  $AGSet.add($AVSets.Name , $TXT);
  }}



#Write CSV Headers
Write-Output ("VMName|Environment|Availability Set|Managed|Location|Fault Domains|Update Domains|OS Type|Managed Disk|OS Storage Account|SKU|OS Disk Name|OS Disk Size"+
  "|DD1 Storage Account|DD1 SKU|DD1 Name|DD1 Size|DD2 Storage Account|DD2 SKU|DD2 Name|DD2 Size|DD3 Storage Account|DD3 SKU|DD3 Name|DD3 Size|DD4 Storage Account|DD4 SKU|DD4 Name|DD4 Size"+
  "|DD5 Storage Account|DD5 SKU|DD5 Name|DD5 Size|DD6 Storage Account|DD6 SKU|DD6 Name|DD6 Size|DD7 Storage Account|DD7 SKU|DD7 Name|DD7 Size|DD8 Storage Account|DD8 SKU|DD8 Name|DD8 Size") | Out-File -FilePath .\AvailabilitySetVirtualMachines.csv -Encoding ascii -Width 10000;
Write-Output ("VMName|Environment|OS Type|Managed Disk|OS Storage Account|SKU|OS Disk Name|OS Disk Size"+
  "|DD1 Storage Account|DD1 SKU|DD1 Name|DD1 Size|DD2 Storage Account|DD2 SKU|DD2 Name|DD2 Size|DD3 Storage Account|DD3 SKU|DD3 Name|DD3 Size|DD4 Storage Account|DD4 SKU|DD4 Name|DD4 Size"+
  "|DD5 Storage Account|DD5 SKU|DD5 Name|DD5 Size|DD6 Storage Account|DD6 SKU|DD6 Name|DD6 Size|DD7 Storage Account|DD7 SKU|DD7 Name|DD7 Size|DD8 Storage Account|DD8 SKU|DD8 Name|DD8 Size") | Out-File -FilePath .\SingleVirtualMachines.csv -Encoding ascii -Width 10000;



#Get All VMs and split in to 2 files
foreach($VM in (Get-AzureRmVM)) {
  $TXT=$VM.Name+"|"+$VM.Tags.Environment+"|"

#Write Single VMs
  if($VM.AvailabilitySetReference -eq $null) {

  #Get OS Disk Storage Account
  $OSSA=$VM.StorageProfile.OSDisk.Vhd.Uri
  $OSSA=$OSSA.substring(8,$OSSA.IndexOf(".")-8)

  #Get Storage Account SKU
  foreach($Account in Get-AzureRmStorageAccount) {if($Account.StorageAccountName -eq $OSSA){$SKU=$Account.sku.Name}}

  #Output all OS Disk Properties
  $TXT=$TXT+$VM.StorageProfile.OsDisk.OsType+"|"+$VM.StorageProfile.OsDisk.ManagedDisk+"|"+$OSSA+"|"+$SKU+"|"+$VM.StorageProfile.OsDisk.Name+"|"+$VM.StorageProfile.OsDisk.DiskSizeGB;

  #Get Data Disk Storage Account
  foreach($DD in $VM.StorageProfile.DataDisks) {
  $DDSA=$DD.Vhd.Uri
  $DDSA=$DDSA.substring(8,$DDSA.IndexOf(".")-8)

  #Get Storage Account SKU
  foreach($Account in Get-AzureRmStorageAccount) {if($Account.StorageAccountName -eq $DDSA){$SKU=$Account.sku.Name}}

  #Output all Data Disk Properties
  $TXT=$TXT+"|"+$DDSA+"|"+$SKU+"|"+$DD.Name+"|"+$DD.DiskSizeGB};

  #Write Full Output
  $TXT

  #Write Output to Single VM CSV File
  Write-Output ($TXT) | Out-File -FilePath .\SingleVirtualMachines.csv -Append -Encoding ascii -Width 10000;



  #Write VMs in Availabiltiy Sets
  } else{
    $AGName=$VM.AvailabilitySetReference.Id.substring($VM.AvailabilitySetReference.Id.LastIndexOf("/availabilitySets/")+18);
    $TXT=$TXT+$AGName+"|"+$AGSet.Get_Item($AGName)+"|"

  #Get OS Disk Storage Account
  $OSSA=$VM.StorageProfile.OSDisk.Vhd.Uri
  $OSSA=$OSSA.substring(8,$OSSA.IndexOf(".")-8)

  #Get Storage Account SKU
  foreach($Account in Get-AzureRmStorageAccount) {if($Account.StorageAccountName -eq $OSSA){$SKU=$Account.sku.Name}}

  #Output all OS Disk Properties
  $TXT=$TXT+$VM.StorageProfile.OsDisk.OsType+"|"+$VM.StorageProfile.OsDisk.ManagedDisk+"|"+$OSSA+"|"+$SKU+"|"+$VM.StorageProfile.OsDisk.Name+"|"+$VM.StorageProfile.OsDisk.DiskSizeGB;

  #Get Data Disk Storage Account
  foreach($DD in $VM.StorageProfile.DataDisks) {
  $DDSA=$DD.Vhd.Uri
  $DDSA=$DDSA.substring(8,$DDSA.IndexOf(".")-8)

  #Get Storage Account SKU
  foreach($Account in Get-AzureRmStorageAccount) {if($Account.StorageAccountName -eq $DDSA){$SKU=$Account.sku.Name}}

  #Output all Data Disk Properties
  $TXT=$TXT+"|"+$DDSA+"|"+$SKU+"|"+$DD.Name+"|"+$DD.DiskSizeGB};

  #Write Full Output
  $TXT


  #Write Output to CSV File
  Write-Output ($TXT) | Out-File -FilePath .\AvailabilitySetVirtualMachines.csv -Append -Encoding ascii -Width 10000;
  }}