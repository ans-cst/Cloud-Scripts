Write-Host ""
Write-Host "ANS Unmodernised Instances"
Write-Host "Version 3.0.0"
Write-Host ""
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."


#Install and Import AzureAD Module
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

#Create Log Output File
$LogFile = "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Log Output from Instance Modernisation Checks..."

#Set CSV Path and Import CSV
$CSVPath = Read-Host "Please input the directory path to the CSV locations"
$CSV = Import-Csv "$CSVPath\Azure Instance Modernisation Table.csv"


#Set CSV Headers
"""VMName"",""ResourceGroup"",""VMSize"",""Location"",""OSType"",""NewSize""" | Out-File -Encoding ASCII -FilePath "$CSVPath\Instance Modernisation Recommendations.csv"


#Create Hash Table of Key Pairs from CSV to determine correct moderinisation approach
$CSVTable=@{}

#Get Number of Columns in CSV
$CSVCount=(get-member -InputObject $CSV[0] -MemberType NoteProperty).count

#NOTE - Assumes Column Headers are named VersionX
foreach($TableEntry in $CSV) {
    #All but last column
    for($First=1;$First -lt $CSVCount;$First++)  {
        #Get version to upgrade from
        $FirstStr=$TableEntry.pSobject.Properties.item("Version"+$First.ToString()).Value
            
        if($FirstStr -ne "N/A") {
            #All remaining columns
            for($Second=$First+1;$Second -le $CSVCount;$Second++) {
                #Get version to upgrade to
                $SecondStr=$TableEntry.pSobject.Properties.item("Version"+$Second.ToString()).Value
        
                if($SecondStr -ne "N/A") {
                    #If from and to are valid write hash table entry
                    $CSVTable[$FirstStr]=$SecondStr
                }
            }
        }
    }
}


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


#Get All Azure VMs
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering all Virtual Machines..."
$AllVMs = Get-AzureRmVM
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] All Virtual Machines gathered successfully"
Write-Host ""


#Process Each VM based on Hash Table Key Value Pairs
foreach ($VM in $AllVMs) {

    #If Hash Table contains the VM Size Output Recommendation
    if ($CSVTable[$VM.HardwareProfile.VmSize]) {
    
    """"+$VM.Name+""","""+$VM.ResourceGroupName+""","""+$VM.HardwareProfile.VmSize+""","""+$VM.Location+""","""+$VM.StorageProfile.OsDisk.OsType+""","""+$CSVTable[$VM.HardwareProfile.VmSize]+"""" | 
    Out-File -Encoding ASCII -FilePath "$CSVPath\Instance Modernisation Recommendations.csv" -Append

    #Write output to Log File
    $LogFile += "`n" + "[$(get-date -Format "dd/mm/yy hh:mm:ss")] " + $VM.Name + "can be modernised to " + $CSVTable[$VM.HardwareProfile.VmSize]
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name " can be modernised to" $CSVTable[$VM.HardwareProfile.VmSize]
    } 
    
    else {
    #Write output to Log File
    $LogFile += "`n" + "[$(get-date -Format 'dd/mm/yy hh:mm:ss')] " + $VM.Name + " cannot be modernised"
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name "cannot be modernised" 
    }
}

#Export Log File
Out-File -InputObject $LogFile -FilePath "$CSVPath\Moderinsation Log.txt"