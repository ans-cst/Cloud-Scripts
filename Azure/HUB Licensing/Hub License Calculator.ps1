Write-Host ""
Write-Host "HUB Licensing Calculator"
Write-Host "Version 1.0.1"
Write-Host ""
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


#Create New Excel Workbook
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Excel Document with HUB Recommedations"
$xl = New-Object -ComObject Excel.Application
$xl.visible=$true 

#Add Workbook and Sheets
$xl.Workbooks.Add()
$xl.sheets.Add()
$xl.sheets.Add()

#Interate through each Sheet
foreach ($sheet in $xl.sheets) {
  switch ($sheet.name) {
    "Sheet1" {
      #Set Sheet Name and Column Headers
      $sheet.name = "Instances for HUB" 
      $sheet.range("A1:G1").cells = ("VMName","ResourceGroup","Type","Cost (PCM)","Saving (PCM)","Licenses","Saving Per License")
      $HubSheet=$sheet
    }
    "Sheet2" { 
      #Set Sheet Name and Column Headers
      $sheet.name = "Rate Card"
      $sheet.range("A1:E1").cells = ("VMSize","RequiredLicenses","CostPCM","SavingPCM","SavingsPerLicense")

      #Import Rate Card CSV to Variable
      $CSV = Import-Csv "RateCardPCM.csv"
      $RateCardRowCount=1

      #Import Rate Card CSV Data to Sheet2
      foreach ($Row in $CSV) {
        $RateCardRowCount++
        $sheet.range("A"+$RateCardRowCount.ToString()+":"+"E"+$RateCardRowCount.ToString()).cells=($Row.VMSize,$Row.RequiredLicenses,$Row.CostPCM,$Row.SavingPCM,$Row.SavingsPerLicense)
      }
    }
    #Delete Sheet 3 and 4
    "Sheet3" { 
      #Set Sheet Name and Column Headers
      $sheet.name = "Instances On HUB"
      $sheet.range("A1:C1").cells = ("Name","Type","Licenses")
      $ExistingHubSheet=$sheet
    }
    "Sheet4" { $sheet.delete() }
    "Sheet5" { $sheet.delete() }
    }
  }

#Set RowCounts
$HubRowCount=1
$ExistingHubRowCount=1
 
foreach ($VM in Get-AzureRmVm) {
  if ($VM.StorageProfile.OsDisk.OsType -eq 0) {
    #Output VMs with HUB Licensing Disabled
    if ( -not ($VM.LicenseType)) {
      $HubRowCount++
      $HubSheet.range("A"+$HubRowCount.ToString()+":"+"C"+$HubRowCount.ToString()).cells=($VM.Name,$VM.ResourceGroupName,$VM.HardwareProfile.VmSize)
      $Lookup='=VLOOKUP(B'+$HubRowCount.ToString()+',''Rate Card''!$A$2:$E$'+$HubRowCount.ToString()
      $HubSheet.range("D"+$HubRowCount.ToString()+":"+"D"+$HubRowCount.ToString()).formula=$Lookup+',3)'
      $HubSheet.range("E"+$HubRowCount.ToString()+":"+"E"+$HubRowCount.ToString()).formula=$Lookup+',4)'
      $HubSheet.range("F"+$HubRowCount.ToString()+":"+"F"+$HubRowCount.ToString()).formula=$Lookup+',2)'
      $HubSheet.range("G"+$HubRowCount.ToString()+":"+"G"+$HubRowCount.ToString()).formula=$Lookup+',5)'
    } 

    #Output VMs with HUB Licensing Enabled
    else {
      $ExistingHubRowCount++
      $ExistingHubSheet.range("A"+$ExistingHubRowCount.ToString()+":"+"B"+$ExistingHubRowCount.ToString()).cells=($VM.Name,$VM.HardwareProfile.VmSize)
      $Lookup='=VLOOKUP(B'+$ExistingHubRowCount.ToString()+',''Rate Card''!$A$2:$B$'+$ExistingHubRowCount.ToString()
      $ExistingHubSheet.range("C"+$ExistingHubRowCount.ToString()+":"+"C"+$ExistingHubRowCount.ToString()).formula=$Lookup+',2)'
    }
  }
}

#Sort by Savings Per License and Hide Column
$HubSheet.Activate() 
$HubSheet.UsedRange.Sort($HubSheet.Range("F2:F"+$HubRowCount.ToString()),2)
$HubSheet.Columns.Item(6).Hidden = $True

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Excel Document Created Successfully!"