Write-Host ""
Write-Host "ANS Azure Backup Vault Configuration"
Write-Host "Version 1.0.0"
Write-Host ""
Write-Host ""

#Install/Import AzureAD Module
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



#Set CSV Path
$CSVPath = Read-Host "Please input the output directory path for the CSV"

#Set CSV Headers for Policies in Backup Information CSV
"""Vault Name"",""Redundancy"",""Location"",""Policy Name"",""WorkLoad Type"",""Run Frequency"",""Run Time"",""Daily Retention"",""Weekly Retention"",""Monthly Retention"",""Yearly Retention""" | 
Out-File -Encoding ASCII -FilePath "$CSVPath\Backup Vault Information.csv"



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

#Set Custom Tags to output
$TagSearch1 = Read-Host "Please set the 1st tag key to include in the output"
$TagSearch2 = Read-Host "Please set the 2nd tag key to include in the output"


#Gather Backup Policies
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering Backup Vault Policies"
foreach ($Vault in Get-AzureRmRecoveryServicesVault) {

    #Set each Vault Context
    Set-AzureRmRecoveryServicesVaultContext -Vault $Vault
    $Redundancy = AzureRM.RecoveryServices\Get-AzureRmRecoveryServicesBackupProperty -Vault $Vault | Select -ExpandProperty BackupStorageRedundancy
    Write-Host "Processing Policies for Vault -"$Vault.Name
    #Get each Policy in the Vault
    foreach ($Policy in Get-AzureRmRecoveryServicesBackupProtectionPolicy) {

        #Write Retention Variables
        $DailyRetention = $Policy.RetentionPolicy.DailySchedule.DurationCountInDays
        $WeeklyRetention = $Policy.RetentionPolicy.WeeklySchedule.DurationCountInWeeks
        $MonthlyRetention = $Policy.RetentionPolicy.MonthlySchedule.DurationCountInMonths
        $YearlyRetention = $Policy.RetentionPolicy.YearlySchedule.DurationCountInYears

        If ($WeeklyRetention -eq $null) {
            $WeeklyRetention = "0"
        }
        If ($MonthlyRetention -eq $null) {
            $MonthlyRetention = "0"
        }
        If ($YearlyRetention -eq $null) {
            $YearlyRetention = "0"
        }

        #Append each Policy to the CSV
        """"+$Vault.Name+""","""+$Redundancy+""","""+$Vault.Location+""","""+$Policy.Name+""","""+$Policy.WorkloadType+""","""+$Policy.SchedulePolicy.ScheduleRunFrequency+""","""+$Policy.SchedulePolicy.ScheduleRunTimes+
        ""","""+$DailyRetention+""","""+$WeeklyRetention+""","""+$MonthlyRetention+""","""+$YearlyRetention+"""" |
        Out-File -Encoding ASCII -FilePath "$CSVPath\Backup Vault Information.csv" -Append
    }
}


#Set CSV Headers for Backup Items in Backup Information CSV
"" 
"" 
"" |
Out-File -Encoding ASCII -FilePath "$CSVPath\Backup Vault Information.csv" -Append

"""Vault Name"",""Redundancy"",""Location"",""ResourceGroup Name"",""VM Name"",""$TagSearch1 Tag"",""$TagSearch2 Tag"",""Protection Policy"",""Protection Status""" | 
Out-File -Encoding ASCII -FilePath "$CSVPath\Backup Vault Information.csv" -Append

#Set CSV Headers in Zombie Backup Items CSV
"""Vault Name"",""Redundancy"",""Location"",""Backup Item Name"",""Policy"",""Protection Status""" |
Out-File -Encoding ASCII -FilePath "$CSVPath\Zombie Backup Items.csv"


#Gather Backup Items
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering Backup Vault Items"
foreach ($Vault in Get-AzureRmRecoveryServicesVault) {

    #Set each Vault Context
    Set-AzureRmRecoveryServicesVaultContext -Vault $Vault
    $Redundancy = AzureRM.RecoveryServices\Get-AzureRmRecoveryServicesBackupProperty -Vault $Vault | Select -ExpandProperty BackupStorageRedundancy

    Write-Host ""
    Write-Host "Processing Backup Items for Vault -"$Vault.Name  
    
    #Get each Container in the Vault 
    foreach ($Container in Get-AzureRmRecoveryServicesBackupContainer -ContainerType "AzureVM") {

        #Get each Backup Item in the Container
        foreach ($Item in Get-AzureRmRecoveryServicesBackupItem -Container $Container -WorkloadType AzureVM) {

        #Set VM and ResourceGroup Variables
        $ItemName = $Item.Name -split ";"
        $VMName = $ItemName[3]
        $ResourceGroupName = $ItemName[2]

        Write-Host "Processing Backup Item" $VMName

        
        #Check VM Exists
        $VM = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -VMName $VMName -ErrorVariable BackupError -ErrorAction SilentlyContinue

        #If VM does not exist write Backup Item to Zombie CSV
        If ($BackupError) {
            Write-Output "$VMName is a Zombie Backup Item"
            """"+$Vault.Name+""","""+$Redundancy+""","""+$Vault.Location+""","""+$VMName+""","""+$Item.ProtectionPolicyName+""","""+$Item.ProtectionStatus+"""" |
            Out-File -Encoding ASCII -FilePath "$CSVPath\Zombie Backup Items.csv" -Append

            $BackupError = $null

        }

        #Get Custom VM Tags Value
        $Tag1 = $VM.Tags.$TagSearch1
        $Tag2 = $VM.Tags.$TagSearch2

        #Append each Backup Item to the Backup Information CSV
        """"+$Vault.Name+""","""+$Redundancy+""","""+$Vault.Location+""","""+$ResourceGroupName+""","""+$VMName+""","""+$Tag1+""","""+$Tag2+""","""+$Item.ProtectionPolicyName+""","""+$Item.ProtectionStatus+"""" |
        Out-File -Encoding ASCII -FilePath "$CSVPath\Backup Vault Information.csv" -Append
        }
    }
}