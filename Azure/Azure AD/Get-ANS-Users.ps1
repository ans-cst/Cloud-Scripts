Write-Host ""
Write-Host "ANS Azure AD Users"
Write-Host "Version 1.0.0"
Write-Host ""
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."

#Install and Import AzureAD Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AzureAD -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AzureAD
    Import-Module -Name AzureAD
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""

#Get the credentials from the Credentials txt file
$FilePath = Read-Host "Please input the directory path to credentials file"
$credentailsAndGroupNames = Get-Content "$FilePath\Credentials & Group Names.txt"
$ansUsername = $($credentailsAndGroupNames[2] -split ": ")[1]
$ansPassword = $($credentailsAndGroupNames[3] -split ": ")[1]
$ansPassword = ConvertTo-SecureString $ansPassword -AsPlainText -Force

$secondLineGroupName = $($credentailsAndGroupNames[8] -split ": ")[1]
$thirdLineGroupName = $($credentailsAndGroupNames[9] -split ": ")[1]

#Loging with the ANS Azure AD Admin account
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Connecting to the ANS Azure AD Admin account..."

$credentials = New-Object System.Management.Automation.PSCredential ($ansUsername, $ansPassword)
Connect-AzureAD -Credential $credentials

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Login successful"
Write-Host ""


#Create the 2nd Line and 3rd Line placeholders
$secondLineMembersCsvString = $null
$thirdLineMembersCsvString = $null

$secondLineMembersCsvString = @"
DisplayName,Email

"@


$thirdLineMembersCsvString = @"
DisplayName,Email

"@


#Get Group Memberships

#Get 2ndLine Group Members
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting 2nd Line Group Membership..."

$2ndLineGroup = Get-AzureADGroup -SearchString $secondLineGroupName
$2ndLineMembers = Get-AzureADGroupMember -ObjectId $2ndLineGroup.ObjectId

foreach ($Member in $2ndLineMembers) {
    #Write Users UPN and Display Name to CSV
    $email = $Member.UserPrincipalName
    $secondLineMembersCsvString += @" 
$($member.DisplayName),$email

"@
    }
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] 2nd Line Group Membership Complete"



Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting 3rd Line Group Membership..."

#Get 3rdLine Group Members
$3rdLineGroup = Get-AzureADGroup -SearchString $thirdLineGroupName
$3rdLineMembers = Get-AzureADGroupMember -ObjectId $3rdLineGroup.ObjectId

foreach ($Member in $3rdLineMembers) {
    #Write Users UPN and Display Name to CSV
    $email = $Member.UserPrincipalName
    $thirdLineMembersCsvString += @" 
$($member.DisplayName),$email

"@
    }
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] 3rd Line Group Membership Complete"

#Output the 2nd Line users to a CSV file
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Writing out CSV file $FilePath\2nd Line ANS Users.csv"
Out-File -InputObject $secondLineMembersCsvString -FilePath "$FilePath\2nd Line ANS Users.csv"

#Output the 3rd Line users to a CSV file
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Writing out CSV file $FilePath\3rd Line ANS Users.csv"
Out-File -InputObject $thirdLineMembersCsvString -FilePath "$FilePath\3rd Line ANS Users.csv"

#Disconnect from the ANS Azure AD
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Disconnecting from ANS Azure AD..."
Disconnect-AzureAD
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully disconnected"
Write-Host ""
Write-Host ""