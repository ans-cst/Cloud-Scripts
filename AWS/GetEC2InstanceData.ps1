#Set-ExecutionPolicy -scope CurrentUser Unrestricted
Import-Module AWSPowerShell

Parameters:
$Account = ""
$AccessKey = ""
$SecretKey = ""
$TagKey = "tag:"
$TagValue = ""

#Login to AWS Account
Write-Host "Processing: " $Account
Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey ;

#Get All EC2 Instances with Tag
$Region = Get-AWSRegion
$ACCOUNTInstances = foreach ($reg in $Region)
{
Get-EC2Instance -Region $reg -Filter @{name=$TagKey; values=$TagValue};
}

#Build Data Table
$DTACCOUNT = New-Object System.Data.DataTable

#Add Data Table Headers
[void]$DTACCOUNT.Columns.Add("AccountName")
[void]$DTACCOUNT.Columns.Add("InstanceName")
[void]$DTACCOUNT.Columns.Add("DNSName")
[void]$DTACCOUNT.Columns.Add("InstanceId")
[void]$DTACCOUNT.Columns.Add("State")
[void]$DTACCOUNT.Columns.Add("Platform")
[void]$DTACCOUNT.Columns.Add("InstanceType")
[void]$DTACCOUNT.Columns.Add("PrivateIP")
[void]$DTACCOUNT.Columns.Add("PublicIP")


#For Each EC2 Instance Import Required Data
foreach ($instance in $ACCOUNTInstances.instances)
{
    if ($instance)
    {
        $tagName = $instance.Tags | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value
    
        $row = $DTACCOUNT.NewRow()
        $row.AccountName = $Account
        $row.InstanceName = $tagName
        $row.DNSName = $instance.privatednsname
        $row.InstanceId = $instance.InstanceId
        $row.State = $instance.State.Name
        $row.Platform = $instance.Platform
        $row.InstanceType = $instance.InstanceType
        $row.PrivateIP = $instance.PrivateIPAddress
        $row.PublicIP = $instance.PublicIPAddress
        $DTACCOUNT.rows.Add($row)    
    }
}

$DTACCOUNT | Format-table
Write-Host "EC2 Instance List Gathered for "$Account
