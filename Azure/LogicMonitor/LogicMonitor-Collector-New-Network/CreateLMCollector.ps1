<#
.SYNOPSIS
    This script installs and configures a LogicMonitor Collector Group and Collectors using the LogicMonitor rest API
.DESCRIPTION
    This script installs and configures a LogicMonitor Collector Group and Collectors using the LogicMonitor rest API, the script initially creates the collector group and collectors in LogicMonitor,
    then downloads the LogicMonitor installer and excecutes the installation.
.NOTES
    File Name  : CreateLMCollector.ps1
    Author     : Ryan Froggatt - ryan.froggatt@ansgroup.co.uk
    Owner      : ANS Group
    Web:       : http://www.ans.co.uk  
.LINK
    http://www.ans.co.uk
#>

Param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage="LM Access Id:")]
    [string]$accessId,
    [Parameter(Mandatory=$true, Position=0, HelpMessage="LM Access Key:")]
    [string]$accessKey,
    [Parameter(Mandatory=$true, Position=0, HelpMessage="LM Collector Size(small,medium,large):")]
    [string]$collectorSize,
    [Parameter(Mandatory=$true, Position=0, HelpMessage="LM Host")]
    [string]$lmHost,
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Customers Collector Group Name")]
    [string]$customerName
)


<# ***************************** Variables and Functions *************************** #>
$epoch = [Math]::Round((New-TimeSpan -start (Get-Date -Date "1/1/1970") -end (Get-Date).ToUniversalTime()).TotalMilliseconds)
$path = "C:\ANS"

function signedHeaders($accessId, $accessKey, $requestVars, $epoch)
{
    <# Construct Signature #>
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($accessKey)
    $signatureBytes = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($requestVars))
    $signatureHex = [System.BitConverter]::ToString($signatureBytes) -replace '-'
    $signature = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($signatureHex.ToLower()))

    <# Construct Headers #>
    $auth = 'LMv1 ' + $accessId + ':' + $signature + ':' + $epoch
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization",$auth)
    $headers.Add("Content-Type",'application/json')

    return $headers
}

function createLmCollector($collectorGroupId, $customerName, $backupAgentId)
{
    Write-Host "Creating LogicMonitor collector"
    <# request details #>
    $httpVerb = 'POST'
    $resourcePath = '/setting/collectors'
    $queryParams = ''
    if($backupAgentId)
    {
        $collectorType = "Primary"
        $data = '{"collectorGroupId": '+ $collectorGroupId +',"description": "' + $customerName + ' - ' + $collectorType + '","backupAgentId":'+ $backupAgentId +'}'
    }else{
        $collectorType = "Secondary"
        $data = '{"collectorGroupId": '+ $collectorGroupId +',"description": "' + $customerName + ' - ' + $collectorType + '"}'
    }

    <# Construct URL #>
    $url = 'https://' + $lmHost + '.logicmonitor.com/santaba/rest' + $resourcePath + $queryParams

    <# Concatenate Request Details #>
    $requestVars = $httpVerb + $epoch + $data + $resourcePath

    <# Make Request #>
    $response = Invoke-RestMethod -Uri $url -Method $httpVerb -Body $data -Header (signedHeaders $accessId $accessKey $requestVars $epoch)

    Write-Host $response.data
    Write-Host $response.status

    <# Check is response is succesful and continue #>
    if($response.status -eq 200){
        return $response.data.id
    }else{
        throw "Somthing went wrong creating collector"
    } 
}

function getLmCollector($customerName)
{
    <# request details #>

    $httpVerb = 'GET'
    $resourcePath = '/setting/collectors'
    $queryParams = '?fields=id,description,hostname&filter=description:' + $customerName + ' - Secondary'
    <# Construct URL #>
    $url = 'https://' + $lmHost + '.logicmonitor.com/santaba/rest' + $resourcePath + $queryParams
    
    <# Concatenate Request Details #>
    $requestVars = $httpVerb + $epoch + $resourcePath
    
    <# Make Request #>
    $response = Invoke-RestMethod -Uri $url -Method $httpVerb -Header (signedHeaders $accessId $accessKey $requestVars $epoch)

    <# Check if customer was retrieved #>
    if($response.status -eq 200 -And $response.data.total -eq 1 ){     
        return $response.data.items.id
    }else{
        return 0
    }
}

function createDirectory($path)
{
    if(!(test-path $path))
    {
        mkdir -Path $path
    }   
}

function downloadLmInstaller($collectorId, $collectorSize)
{
    <# request details #>
    $httpVerb = 'GET'
    $resourcePath = '/setting/collectors/' + $collectorId +'/installers/Win64'
    $queryParams = '?collectorSize=' + $collectorSize 

    <# Construct URL #>
    $url = 'https://' + $lmHost + '.logicmonitor.com/santaba/rest' + $resourcePath + $queryParams

    <# Concatenate Request Details #>
    $requestVars = $httpVerb + $epoch + $resourcePath

    <# Make Request #>
    Invoke-RestMethod -Uri $url -Method $httpVerb -Header (signedHeaders $accessId $accessKey $requestVars $epoch) -OutFile "$path\LogicMonitorSetup.exe"

    <# Check if file exists continue #>
    if(test-path "$path\LogicMonitorSetup.exe"){
        Write-Host "Downloaded LogicMonitor collector installer successfuly"
    }else{
        throw "Somthing went wrong downloading collector"
    } 
}

function getCollectorGroup($customerName)
{
    <# request details #>

    $httpVerb = 'GET'
    $resourcePath = '/setting/collectors/groups'
    $queryParams = '?fields=id,name,description&filter=name:' + [uri]::EscapeDataString($customerName)
    <# Construct URL #>
    $url = 'https://' + $lmHost + '.logicmonitor.com/santaba/rest' + $resourcePath + $queryParams
    
    <# Concatenate Request Details #>
    $requestVars = $httpVerb + $epoch + $resourcePath
    
    <# Make Request #>
    $response = Invoke-RestMethod -Uri $url -Method $httpVerb -Header (signedHeaders $accessId $accessKey $requestVars $epoch)

    <# Check if customer was retrieved #>
    if($response.status -eq 200 -And $response.data.total -eq 1 ){     
        return $response.data.items.id
    }else{
        return 0
    }
}

function createCollectorGroup($customerName)
{
    <# request details #>
    $httpVerb = 'POST'
    $resourcePath = '/setting/collectors/groups'
    $queryParams = ''
    $data = '{"name": "' + $customerName +'", "description": "' + $customerName +' Collector Group"}'
    <# Construct URL #>
    $url = 'https://' + $lmHost + '.logicmonitor.com/santaba/rest' + $resourcePath + $queryParams
    
    <# Concatenate Request Details #>
    $requestVars = $httpVerb + $epoch + $data + $resourcePath
    
    <# Make Request #>
    $response = Invoke-RestMethod -Uri $url -Method $httpVerb -Body $data -Header (signedHeaders $accessId $accessKey $requestVars $epoch)

    <# Check if customer was retrieved #>
    if($response.status -eq 200){
        return $response.data.id
    }else{
        throw "Somthing went wrong creating customer group"
    }
}

<# ***************************** Script *************************** #>

# Create Collector Group if it does not exist
if((getCollectorGroup $customerName) -eq 0 )
{
    (createCollectorGroup $customerName)
}

# Get Collector Group Id
$collectorGroupId = (getCollectorGroup $customerName)

# Check if Secondary collector exists, then create a Secondary or Primary on test result
if((getLmCollector $customerName) -eq 0)
{
    #Create a Secondary Collector in LogicMonitor
    $backupAgentId = ''
    $collectorId = (createLmCollector $collectorGroupId $customerName $backupAgentId)
}else{
    #Create a Primary Collector in LogicMonitor
    $backupAgentId = (getLmCollector $customerName)
    $collectorId = (createLmCollector $collectorGroupId $customerName $backupAgentId)
}

# Create Directory
(createDirectory $path)
# Download Installer
(downloadLmInstaller $collectorId $collectorSize)
# Install Collector
Start-Process "$path\LogicMonitorSetup.exe" -ArgumentList "/q" -Wait -Verb RunAs




