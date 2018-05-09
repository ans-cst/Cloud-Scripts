Write-Output "ANS - AWS - Tag Associated EC2 Resources"
Write-Output "Version 1.1.0"
Write-Output ""


#Import AWS PowerShell Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AWSPowerShell -ErrorVariable ModuleError
if ($ModuleError) {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Module Error - $ModuleError"
Write-Output ""
}
else {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module <br />"
Write-Output ""
}


#Get All EC2 Instances
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering all EC2 Instances in account..."
foreach ($reg in Get-AWSRegion) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" "Processing Region $reg"

    #Process Each Instance
    foreach ($Instance in (Get-EC2Instance -Region $reg).instances) {
        
        #Get Instance Tags
        $Tags = $Instance.Instances.Tags
        $InstanceId = $Instance.Instances.InstanceId

        #Set Name Tag to Instance Name
        foreach ($Key in $Tags | Where-Object {$_.Key -eq 'Name'}) {
        $Key.Key = 'Instance Name'
        } 
        

        #Get Associated EBS Volumes
        $Volumes = Get-EC2Volume -Region $reg | Where-Object {$_.Attachment.InstanceId -eq $InstanceId}

        #Write Tags to Associated EBS Volumes
        foreach ($Volume in $Volumes) {           
            New-EC2Tag -Region $reg -Resource $Volume.VolumeId -Tag $Tags
        }
#    }
#}



        #Get Associated Snapshots for EBS Volumes
        foreach ($Volume in $Volumes) {
            $Snapshots = Get-EC2Snapshot -Region $reg | Where-Object {$_.VolumeId -eq $Volume.VolumeId}

            #Write Tags to Associated Snapshots if Snapshots Exist
            If ($Snapshots -ne $null) {
                foreach ($Snapshot in $Snapshots) {
                    New-EC2Tag -Region $reg -Resource $Snapshot.SnapshotId -Tag $Tags
                }
            }
        }



        #Write Tags to Associated Network Interfaces
        $Interfaces = $Instance.Instances.NetworkInterfaces

        foreach ($Interface in $Interfaces) {
            New-EC2Tag -Region $reg -Resource $Interface.NetworkInterfaceId -Tag $Tags
        }



        #Write Tags to Assocaited Elastic IPs
        $ElasticIPs = Get-EC2Address -Region $reg | Where-Object {$_.InstanceId -eq $InstanceId}

        #If Elastic IPs Exist Write Tags to each IP
        If ($ElasticIPs -ne $null) {
            foreach ($IP in $ElasticIPs) {
                New-EC2Tag -Region $reg -Resource $IP.AllocationId -Tag $Tags
            }
        }
    }
}
