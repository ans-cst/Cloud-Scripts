Write-Output ""
Write-Output "ANS - Export EA Price List"
Write-Output "Version 1.0.0"
Write-Output ""

#Gather Info
$EnrollmentID = Read-Host "Input Customer's Enrollment ID"
$APIKey = Read-Host "Input Customer's EA API Key"
$CSVPath = Read-Host "Enter Directory Path to output file"


#Invoke API Request
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Invoking API Request"

$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Headers.Add("Authorization", "Bearer $APIKey")

$JSON = Invoke-RestMethod -Uri https://consumption.azure.com/v2/enrollments/$EnrollmentID/pricesheet -Method Get -Headers $Headers -ErrorVariable APIError -ErrorAction SilentlyContinue

if ($JSON -ne $null) {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EA Price List Retreived successfully"
}
else {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] API Request Error - $APIError"
}


#Convert API Response from JSON to CSV
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converting JSON response to CSV"
$JSON | Export-CSV "$CSVPath\$EnrollmentID-PriceList.csv" -NoTypeInformation
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] JSON Response converted to CSV successfully"