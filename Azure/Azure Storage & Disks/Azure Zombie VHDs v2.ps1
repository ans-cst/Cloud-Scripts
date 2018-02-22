Write-Host ""
Write-Host "ANS Azure Zombie VHDs"
Write-Host "Version 2.0.0"
Write-Host ""
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."

#Install/Import AzureAD Module
$Module = Get-Module -Name AzureRM
if ($Module -eq $null) {
    Install-Module -Name AzureRM
    Import-Module -Name AzureRM
}
else {
    Import-Module -Name AzureRM
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported Module"
Write-Host ""


#Set Script Option
Write-Host ""
Write-Host "There are 3 options for using this script."
Write-Host "1. Filter by storage account, specifying the RG and SA name - quick"
Write-Host "2. Filter using a match in a SA name - moderate"
Write-Host "3. No filter. Gets all VHDs in all storage accounts in the subscription - slow"
Write-Host ""
Write-Host ""
$Option = Read-Host "Specify one of the above options [1, 2, 3]"
Write-Host ""

#Check Script Option is valid
while ($Option -ne "1" -and $Option -ne "2" -and $Option -ne "3"){
    Write-Host "Option is invalid"
    $Option = Read-Host "Please specify option 1, 2 or 3"
    Write-Host ""
}

#Set CSV Headers and Path
$CSVPath = Read-Host "Please specify CSV output directory"
Write-Host ""
"""Uri"",""AttachedToVMName"",""Lease Status"",""Lease State"",""Storage Type"",""Storage Tier"",""StorageAccount Name"",""Location"",""Resource Group"",""Size GB""" | Out-File -Encoding ASCII -FilePath "$CSVPath\VHD Information.csv"


#Login to Azure AD
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Login-AzureRmAccount
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logged in to Azure Account successfully"
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


#Option 1 - Collect for Single Storage Account
If ($Option -eq "1") {

    #Set Storage Account Name and Resource Group Parameters
    $ResourceGroup = Read-Host "Specify the Resource Group of the Storage Account"
    $StorageAccountName = Read-Host "Specify the Name of the Storage Account"
    Write-Host ""

    $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName
    foreach ($Container in $StorageAccount | Get-AzureStorageContainer) {
        Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Container -" $Container.Name
        foreach ($VHD in $Container | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}) {
        
            #Append VHD to CSV
            """"+$VHD.ICloudBlob.Uri.AbsoluteUri+""","""+$VHD.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName+""","""+$VHD.ICloudBlob.Properties.LeaseStatus+""","""+
            $VHD.ICloudBlob.Properties.LeaseState+""","""+$StorageAccount.Sku.Name+""","""+$StorageAccount.Sku.Tier+""","""+$StorageAccount.StorageAccountName+""","""+
            $StorageAccount.Location+""","""+$StorageAccount.ResourceGroupName+""","""+$VHD.Length / 1024 / 1024 / 1024+"""" | 
            Out-File -Encoding ASCII -FilePath "$CSVPath\VHD Information.csv" -Append
        }
    }
}


#Option 2 - Collect Storage Accounts that match input string
If ($Option -eq "2") {
    
    #Set Search String Parameter
    $SearchString = Read-Host "Specify the string to search for in the Storage Account Name"

    #Parse each storage account based on input string
    foreach ($StorageAccount in Get-AzureRmStorageAccount | Where {$_.StorageAccountName -match $SearchString}) {
        Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" $StorageAccount.StorageAccountName

        #Parse each container in Storage Account
        foreach ($Container in $StorageAccount | Get-AzureStorageContainer) {
            Write-Host "                    Processing Container -" $Container.Name

            #Parse each VHD in Container
            foreach ($VHD in $Container | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}) {
        
                #Append VHD to CSV
                """"+$VHD.ICloudBlob.Uri.AbsoluteUri+""","""+$VHD.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName+""","""+$VHD.ICloudBlob.Properties.LeaseStatus+""","""+
                $VHD.ICloudBlob.Properties.LeaseState+""","""+$StorageAccount.Sku.Name+""","""+$StorageAccount.Sku.Tier+""","""+$StorageAccount.StorageAccountName+""","""+
                $StorageAccount.Location+""","""+$StorageAccount.ResourceGroupName+""","""+$VHD.Length / 1024 / 1024 / 1024+"""" | 
                Out-File -Encoding ASCII -FilePath "$CSVPath\VHD Information.csv" -Append
            }
        }
    }
}



#Option 3 - Collect data for all storage accounts.
If ($Option -eq "3") {
    foreach ($StorageAccount in Get-AzureRmStorageAccount) {
        Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing Storage Account -" $StorageAccount.StorageAccountName

        foreach ($Container in $StorageAccount | Get-AzureStorageContainer) {
            Write-Host "                    Processing Container -" $Container.Name
            foreach ($VHD in $Container | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}) {
        
                #Append VHD to CSV
                """"+$VHD.ICloudBlob.Uri.AbsoluteUri+""","""+$VHD.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName+""","""+$VHD.ICloudBlob.Properties.LeaseStatus+""","""+
                $VHD.ICloudBlob.Properties.LeaseState+""","""+$StorageAccount.Sku.Name+""","""+$StorageAccount.Sku.Tier+""","""+$StorageAccount.StorageAccountName+""","""+
                $StorageAccount.Location+""","""+$StorageAccount.ResourceGroupName+""","""+$VHD.Length / 1024 / 1024 / 1024+"""" | 
                Out-File -Encoding ASCII -FilePath "$CSVPath\VHD Information.csv" -Append
            }
        }
    }
}