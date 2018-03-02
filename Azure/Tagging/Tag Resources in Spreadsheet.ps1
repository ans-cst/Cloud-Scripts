Write-Host ""
Write-Host "ANS - Tag Resources from Spreadsheet"
Write-Host "Version 1.0.0"
Write-Host ""
Write-Host ""
Write-Host "Before Proceeding please ensure the CSV headers are in the below format:"
Write-Host "Resource Name  |  Resource Id  |  Tag1  |  Tag2  |  Tag3  |  Tag4"
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

#Import CSV
$CSVPath = Read-Host "Please input the file path to the CSV"
$CSV = Import-Csv $CSVPath

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



foreach ($Item in $CSV) {
    
    #Get Resource and Current Tags
    $Resource = Get-AzureRmResource -ResourceId $Item.'Resource Id'
    $ResourceTags = $Resource.Tags

    #Get Tag Keys from CSV
    $Keys = $CSV | Get-Member | where-object {$_.MemberType -eq "NoteProperty" -and $_.Name -ne "Resource Name" -and $_.Name -ne "Resource Id"}

    #Add each tag Key and Value to the current Tags
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering tags from spreadsheet for -" $Item."Resource Name"
    foreach ($Key in $Keys) {
        
        $KeyName = $Key.Name
        $ResourceTags.$KeyName = $Item.$KeyName
    }

    #Add the new Tags to the resource
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding tags to resource" +$Item."Resource Name"
    Set-AzureRmResource -Tag $ResourceTags -ResourceId $Item.'Resource Id' -Force


}