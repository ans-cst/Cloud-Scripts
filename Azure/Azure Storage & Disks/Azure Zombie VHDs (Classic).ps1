Write-Host ""
Write-Host "ANS Azure Zombie VHDs (Classic)"
Write-Host "Version 2.0.0"
Write-Host ""
Write-Host ""

#Install/Import Azure Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name Azure -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name Azure
    Import-Module -Name Azure
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported Module"
Write-Host ""

#Login to Azure AD
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Add-AzureAccount
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logged in to Azure Account successfully"
Write-Host ""

#Select SubscriptionId
$SubId = Read-Host "Please input your Subscription Id"
while ($SubId.Length -le 35) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $SubId = Read-Host "Please input your Subscription Id"
}
Select-AzureSubscription -SubscriptionId $SubId
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Host ""


#Set CSV Headers and Path
$CSVPath = Read-Host "Please specify CSV output directory"

$DISKOUTPUT = @()
foreach ($STORAGEACCOUNT in Get-AzureStorageAccount )
    {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account - $STORAGEACCOUNT"
    
    Get-AzureDisk | where-Object {$_.MediaLink.Host.Contains($STORAGEACCOUNT.StorageAccountName)} | Where-Object -Property AttachedTo -EQ $null | 
    Select @{L="StorageAccount";E={$STORAGEACCOUNT.StorageAccountName}}, DiskName, DiskSizeInGB, SourceImageName, Location | ForEach-Object {
        $_
        $tmpObj = New-Object -TypeName PSObject
        $tmpObj | Add-Member -MemberType Noteproperty -Name "StorageAccount" -Value $STORAGEACCOUNT.StorageAccountName
        $tmpObj | Add-Member -MemberType Noteproperty -Name "StorageAccountSKU" -Value ($STORAGEACCOUNT.AccountType)
        $tmpObj | Add-Member -MemberType Noteproperty -Name "ResourceType" -Value "CLASSIC"
        $tmpObj | Add-Member -MemberType Noteproperty -Name "DiskName" -Value $_.DiskName
        $tmpObj | Add-Member -MemberType Noteproperty -Name "DiskSizeInGB" -Value $_.DiskSizeInGB
        $tmpObj | Add-Member -MemberType Noteproperty -Name "SourceImageName" -Value $_.SourceImageName
        $tmpObj | Add-Member -MemberType Noteproperty -Name "Location" -Value $_.location
        #$tmpObj
        $DISKOUTPUT += $tmpObj
    }
}
$DISKOUTPUT | Export-csv -NoTypeInformation "$CSVPath\Zombie VHDs.csv"



