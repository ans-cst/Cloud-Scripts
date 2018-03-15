Write-Host ""
Write-Host "ANS - Tag Associated VM Resources"
Write-Host "Version 1.0.0"
Write-Host ""
Write-Host ""
Write-Host "This script will tag the below associated resource types for each VM"
Write-Host "- Managed Disks"
Write-Host "- Network Interfaces"
Write-Host "- Public IP Addresses"
Write-Host ""


#Install and Import AzureRM Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AzureRM -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AzureRM
    Import-Module -Name AzureRM
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""

#Login to Azure
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Login-AzureRmAccount
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
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


foreach ($VM in Get-AzureRmVM | Where-Object {$_.Tags -ne $null}) {
    
    #Get Current VM Tags
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting Tags for -" $VM.Name
    $Tags = $VM.Tags
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathered Tags Successfully"
    Write-Host ""


    #Get Associated Network Interfaces and Tag
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Network Interfaces for -" $VM.Name
    $NetworkInterfaceIDs = $VM.NetworkProfile.NetworkInterfaces.Id

    foreach ($Int in $NetworkInterfaceIDs) {

        #Get Interface Name
        $IntName = $Int.Split("/")[8]

        Write-Host "Tagging Interface" $IntName
        Set-AzureRmResource -ResourceId $Int -Tag $Tags -Force
    }

    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Network Interfaces Tagged Successfully"
    Write-Host ""


    #Get Associated Managed Disks and Tag
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Managed Disks for -" $VM.Name

    if ($VM.StorageProfile.OsDisk.ManagedDisk -ne $null) {
        $OSDisk = $VM.StorageProfile.OsDisk.Name
        $DataDisks = $VM.StorageProfile.DataDisks.Name
        $Disks = $OSDisk,$DataDisks

        foreach ($Disk in $Disks) {
            Write-Host "Tagging Managed Disk" $Disk
            $Config = New-AzureRmDiskUpdateConfig -Tag $Tags
            $Disk = Get-AzureRmDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $Disk 
            Update-AzureRmDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $Disk.Name -DiskUpdate $Config
        }
        Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Managed Disks Tagged Successfully"
        Write-Host ""
    }

    else {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name "is using Unmanaged Disks"
    Write-Host ""
    }


    #Get Associated Public IP Addresses and Tag
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Public IPs for -" $VM.Name
    foreach ($Int in $NetworkInterfaceIDs) {
        
        #Get All IP Configuration for Interface
        $Int = Get-AzureRmResource -ResourceId $Int
        $IPConfigurations = $Int.Properties.ipConfigurations

        #Check IP Configurations for Public IPs

        If ($IPConfigurations.properties.publicIPAddress -eq $null) {
        Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] No Public IP Addresses to Tag"
        }

        #If Public IPs exist then Tag
        else {
            foreach ($IP in $IPConfigurations | Where-Object {$_.properties.publicIPAddress -ne $null}) {
                
                #Get Public IP Name
                $PIPName = $IP.properties.publicIPAddress.id.Split("/")[8]

                Write-Host "Tagging Public IP" $PIPName
                Set-AzureRmResource -ResourceId $IP.properties.publicIPAddress.id -Tag $Tags -Force
            }
        }
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Public IPs Tagged Successfully"
    Write-Host ""
    }
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name "Tagged Successfully!"
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Tagging Completed Successfully for all Virtual Machines"
