Write-Host ""
Write-Host "ANS Azure AD Users to Customer Directory"
Write-Host "Version 1.0.0"
Write-Host ""
Write-Host ""

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

#Login to Azure AD
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Connecting to Azure AD..."
$cred = Get-Credential
$tenantid = Read-Host "Please input your Azure Active Directory Tenant/Directory ID"
Connect-AzureAD -Credential $cred -TenantId $tenantid
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Connected to Azure AD successfully"
Write-Host ""


#Set CSV Directory Path and Import CSVs
$CSVPath = Read-Host "Please input the directory path to the CSV locations"
$secondLineInvitations = import-csv -Delimiter ',' "$CSVPath\2nd Line ANS Users.csv"
$thirdLineInvitations = import-csv "$CSVPath\3rd Line ANS Users.csv"
$invitations = $secondLineInvitations + $thirdLineInvitations
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Imported CSV successfully!"
Write-Host ""


#Create Invitations
$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo
$messageInfo.customizedMessageBody = "Hey there! Check this out. I created an invitation through PowerShell"


foreach ($invite in $invitations) {
    #Check if the user exists within the directory
    $result = Get-AzureADUser -SearchString $invite.DisplayName

    #Check if the user doesnt exist before sending the invitation
    if ($result -eq $null) {
        Write-Host "Sending Invitation to " $invite.DisplayName
        New-AzureADMSInvitation -InvitedUserEmailAddress $invite.Email -InvitedUserDisplayName $invite.DisplayName -InviteRedirectUrl https://portal.azure.com -InvitedUserMessageInfo $messageInfo -SendInvitationMessage $true
    }
    else {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] User $($invite.DisplayName) already exists within the customers directory"
    }
}

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Invitiations sent successfully."
Write-Host ""



#Create AzureAD groups
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating 2nd and 3rd Line Azure AD Groups..."

#Check if the 2ndLine Group exists
$2ndLineGroupName = "ANS-SecondLine"
$result = Get-AzureADGroup -SearchString $2ndLineGroupName
$2ndLineGroup = $null

if ($result -eq $null) {
    #If the group does not exist create the group
    $2ndLineGroup = New-AzureADGroup -DisplayName $2ndLineGroupName -MailEnabled $false -MailNickName "ANS-2nd-Line" -SecurityEnabled $true -Description "ANS $2ndLineGroupName security group"

}
else {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] 2nd line group already exists"
    #If the Group exists then get the Group
    $2ndLineGroup = Get-AzureADGroup -SearchString $2ndLineGroupName
}

#Check if the 3rdLine Group exists
$3rdLineGroupName = "ANS-ThirdLine"
$result = Get-AzureADGroup -SearchString $3rdLineGroupName
$3rdLineGroup = $null

if ($result -eq $null) {
    #If the group does not exist create the group
    $3rdLineGroup = New-AzureADGroup -DisplayName $3rdLineGroupName -MailEnabled $false -MailNickName "ANS-2nd-Line" -SecurityEnabled $true -Description "ANS $3rdLineGroupName security group"

}
else {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] 3rd line group already exists"
    #If the Group exists then get the Group
    $3rdLineGroup = Get-AzureADGroup -SearchString $3rdLineGroupName
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Azure AD Groups created successfully"
Write-Host ""



#Create the users within the 2nd Line Group
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding ANS users to the new 2nd Line group..."
foreach ($invite1 in $secondLineInvitations) {
    $User1 = Get-AzureADUser -SearchString $invite1.DisplayName
    while (!$User1) {
        Write-Host "Waiting for "$invite1.DisplayName
        SLEEP 1
        $User1 = Get-AzureADUser -SearchString $invite1.DisplayName
    }

        #Get User Membership
	    $Membership = Get-AzureADUserMembership  -ObjectId $User1.ObjectId

            #If user exists do nothing
            If ($Membership.ObjectId -contains $2ndLineGroup.ObjectId) {
	            Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] User" $User1.DisplayName "already exists within the customers directory"
	        }
            #If the user does not exist add the user to the group
    	    else {
                Add-AzureADGroupMember -ObjectId $2ndLineGroup.ObjectId -RefObjectId $User1.ObjectId
    	    }
}

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Added ANS users to 2nd Line group"
Write-Host ""

#Create the users within the 3rd Line Group
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding ANS users to the new 3rd Line group..."
foreach ($invite2 in $thirdLineInvitations) {
    $User2 = Get-AzureADUser -SearchString $invite2.DisplayName
    while (!$User2) {
        Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting for "$invite2.DisplayName
        SLEEP 1
        $User2 = Get-AzureADUser -SearchString $invite2.DisplayName
    }

        #Get User Membership
	    $Membership = (Get-AzureADUserMembership  -ObjectId $User2.ObjectId | Select ObjectId)

            #If user exists do nothing
            If ($Membership.ObjectId -contains $3rdLineGroup.ObjectId) {
	            Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] User" $User2.DisplayName "already exists within the customers directory"
	        }

            #If the user does not exist add the user to the group
	        else {
                Add-AzureADGroupMember -ObjectId $3rdLineGroup.ObjectId -RefObjectId $User2.ObjectId
            }
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Added ANS users to 3rd Line group"


#Disconnect from the Customers Azure AD
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Disconnecting from the customers Azure AD..."
Disconnect-AzureAD
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully disconnected"
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Done!"