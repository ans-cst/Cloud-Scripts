<#
Three options for using this script.
1. Filter by storage account, specifying the RG and SA name - quick
2. Filter using a match in a Where clause - moderate
3. No filter. Gets all VHDs in all storage accounts in the subscription - slow
#>

#Login-AzureRmAccount

# You may need or want to Select-AzureRmSubscription

# Everything - SLOW
$AllStorageAccounts = Get-AzureRmStorageAccount

# Filter using a match (or a like) - MODERATE
#$AllStorageAccounts = Get-AzureRmStorageAccount | Where {$_.StorageAccountName -match '(accounts)'}

# Filter by single SA - QUICK
#$AllStorageAccounts = Get-AzureRmStorageAccount -ResourceGroupName 'myresourcegroup' -Name 'mystorageaccount'

$AllVHDs = $AllStorageAccounts | Get-AzureStorageContainer | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}

$Uri = foreach ($VHD in $AllVHDs) {

    $StorageAccountName = if ($VHD.ICloudBlob.Parent.Uri.Host -match '([a-z0-9A-Z]*)(?=\.blob\.core\.windows\.net)') {$Matches[0]}

    $StorageAccount = $AllStorageAccounts | Where { $_.StorageAccountName -eq $StorageAccountName }

    $Property = [ordered]@{

        Uri = $VHD.ICloudBlob.Uri.AbsoluteUri;
        AttachedToVMName = $VHD.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName
        LeaseStatus = $VHD.ICloudBlob.Properties.LeaseStatus;
        LeaseState = $VHD.ICloudBlob.Properties.LeaseState;
        StorageType = $StorageAccount.Sku.Name;
        StorageTier = $StorageAccount.Sku.Tier;
        StorageAccountName = $StorageAccountName;
        StorageAccountResourceGroup = $StorageAccount.ResourceGroupName

    }

    New-Object -TypeName PSObject -Property $Property

}

$Uri | Export-Csv -Path '.\DiskLeaseInformation.csv' -NoTypeInformation