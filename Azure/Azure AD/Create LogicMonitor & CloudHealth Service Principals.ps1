Write-Host ""
Write-Host "ANS - Create LogicMonitor & CloudHealth Service Principals"
Write-Host "Version 1.0.0"
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

#Set CSV Path and Import CSV
$FilePath = Read-Host "Please input the directory path to output information to a text file"

#Create Log Output File
"Please provide the below information to ANS" | Out-File -FilePath "$FilePath\ServicePrincipals.txt"

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

#Output Tenant ID
$tenant = Get-AzureRmSubscription -SubscriptionId $SubId
"Tenant Directory ID - " + $tenant.TenantId | Out-File -Encoding Ascii -FilePath "$FilePath\ServicePrincipals.txt" -Append

#Values for CloudHealth Azure AD app:
$chtappName = "ans_cloudhealth"
$chturi = "https://apps.cloudhealthtech.com"
$chtsecret = Read-Host -AsSecureString "Please input a password for the CloudHealth App Registration"

# Create the CloudHealth Azure AD app
$chtAdApplication = New-AzureRmADApplication -DisplayName $chtappName -HomePage $chturi -IdentifierUris $chturi -Password $chtsecret

# Create a Service Principal for the CloudHealth app
$chtsvcprincipal = New-AzureRmADServicePrincipal -ApplicationId $chtAdApplication.ApplicationId

#Sleep for 15 seconds
SLEEP 15

# Assign the Reader RBAC role to the CloudHealth service principal
$chtroleassignment = New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $chtAdApplication.ApplicationId.Guid

#Output Required CloudHealth Information
"CloudHealth Application ID - " + $chtsvcprincipal.ApplicationId | Out-File -FilePath "$FilePath\ServicePrincipals.txt" -Append

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CloudHealth App Registration Completed successfully!"


#Values for LogicMonitor Azure AD app:
$lmappName = "ans_logicmonitor"
$lmuri = "https://ans.logicmonitor.com/"
$lmsecret = Read-Host -AsSecureString "Please input a password for the LogicMonitor App Registration"

# Create the Azure AD  LogicMonitor app
$lmAdApplication = New-AzureRmADApplication -DisplayName $lmappName -HomePage $lmuri -IdentifierUris $lmuri -Password $lmsecret

# Create a Service Principal for the  LogicMonitor app
$lmsvcprincipal = New-AzureRmADServicePrincipal -ApplicationId $lmAdApplication.ApplicationId

#Sleep for 15 seconds
SLEEP 15

# Assign the Reader RBAC role to the LogicMonitor service principal
$lmroleassignment = New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $lmAdApplication.ApplicationId.Guid

#Output Required Information
"LogicMonitor Application ID - " + $lmsvcprincipal.ApplicationId | Out-File -FilePath "$FilePath\ServicePrincipals.txt" -Append
"Please provide the text file output along with the passwords used for each App Registration to ANS." | Out-File -FilePath "$FilePath\ServicePrincipals.txt" -Append

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] LogicMonitor App Registration Completed successfully!"

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Please provide the text file output along with the passwords used for each App Registration to ANS."