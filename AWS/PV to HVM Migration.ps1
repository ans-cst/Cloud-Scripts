Write-Host ""
Write-Host "ANS ParaVirtual to Hardware Virtual Machine Kernel Migration"
Write-Host "Version 2.0.0"
Write-Host ""
Write-Host ""

#Install and Import AWS PowerShell Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AWSPowerShell -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AWSPowerShell
    Import-Module -Name AWSPowerShell
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""

#Login to AWS Account
$AccessKey = Read-Host "Please input your AWS Access Key"
$SecretKey = Read-Host "Please input your AWS Secret Key"
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to AWS Account..."
Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey ;
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to AWS Account"
Write-Host ""

#Get PV Instance Root Volume
$Region = Read-Host "Please input your AWS Region"
$PVInstanceID = Read-Host "Please input your Instance ID for your ParaVirtual Instance"
$PVVolumes = (Get-EC2Volume -Region $Region | ? { $_.Attachments.InstanceId -eq $PVInstanceId})
$PVVolume = (Get-EC2Volume -Region $Region | ? { $_.Attachments.InstanceId -eq $PVInstanceId})[0]

#Create Snapshot of PV Instance Root Volume
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating EBS Volume Snapshot of ParaVirtual Volume"
$Snapshot = New-EC2Snapshot -Region $Region -VolumeId $PVVolume.VolumeId -Description "Migrating to HVM Based AMI"
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EBS Snapshot Created Successfully"
Write-Host ""


#Input the Instance details of your new HVM Instance
$HVMName = Read-Host "Please input the name for your new HVM Instance"
$HVMAMI = Read-Host "Please input the AMI ID for your new HVM Instance"
$HVMType = Read-Host "Please input the instance type for your new HVM Instance"
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating new HVM Based EC2 Instance"

#Get PV Instance Configuration
$PVInstance =  (Get-EC2Instance -Region $Region -InstanceId $PVInstanceID).Instances

#Build HVM Instance Tags
$Tags = new-object Amazon.EC2.Model.TagSpecification
$Tags.ResourceType = "instance"

#Copy Tags from PV Instance
foreach ($Key in $PVInstance.Tags | Where-Object {$_.Key -ne "Name"}) {
    $Tag = @{ key = $Key.key; Value = $Key.Value}
    $Tags.Tags.Add($Tag)
}
#Set New Name Tag
$Tag = @{ key = "Name"; Value = $HVMName} 
$Tags.Tags.Add($Tag)

#Create the HVM Instance
$HVMInstance = (New-EC2Instance -ImageId $HVMAMI -AvailabilityZone $PVVolume.AvailabilityZone -Region $Region -InstanceType $HVMType -MaxCount 1 `
-KeyName $PVInstance.KeyName -SecurityGroupId $PVInstance.SecurityGroups.GroupId -SubnetId $PVInstance.SubnetId -InstanceProfile_Name $PVInstance.IamInstanceProfile `
-TagSpecification $Tags).Instances

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] New HVM Instance" $HVMInstance.InstanceId "created successfully"
Write-Host ""

#Wait for Snapshot to enter the completed state
Do {
$SnapshotState = (Get-EC2Snapshot -Region $region -SnapshotId $Snapshot.SnapshotId).State
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting for snapshot to enter the completed state"
Write-Host ""
SLEEP 5
}
Until ($SnapshotState = "completed")

#Create New EBS Volume from PV Root Volume Snapshot
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating EBS Volume from ParaVirtual Snapshot"
$MigrationVolume = New-EC2Volume -Region $Region -AvailabilityZone $PVVolume.AvailabilityZone -SnapshotId $Snapshot.SnapshotId -VolumeType $PVVolume.VolumeType.Value
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Created EBS Volume from ParaVirtual Snapshot successfully"
Write-Host ""

#Wait for HVM Instance to enter the running state
Do {
    $HVMInstanceState = (Get-EC2Instance -InstanceId $HVMInstance.InstanceId -Region $Region).Instances.State.Name.Value
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting for instance to enter the running state"
    SLEEP 5
}
Until ($HVMInstanceState -eq "running")
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Instance" $HVMInstance.InstanceId "has now entered the running state"
Write-Host ""


#Check New EBS Volume is Available
Do {
    $MigrationVolumeState = (Get-EC2Volume -Region $Region -VolumeId $MigrationVolume.VolumeId).State
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting for Volume to finish creating"
    SLEEP 5
}
Until ($MigrationVolumeState -eq "available")
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EBS Volume" $MigrationVolume.VolumeId "Created Successfully"
Write-Host ""

#Attach the New EBS volume to the new HVM Instance
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Attaching EBS Volume to HVM Instance"
Add-EC2Volume -Region $Region -InstanceId $HVMInstance.InstanceId -VolumeId $MigrationVolume.VolumeId -Device /dev/sdm
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EBS Volume Attached to HVM Instance successfully"
Write-Host ""



#Run Commands to Migrate HVM Kernel to EBS Volume

#$OSHashTable = @{ AmazonLinux = "URL" ; RedHat = "URL" ; CentOS = "" ; Windows = "URL" } ;
#Write-Host "Please enter one of the below Operating System Versions: 
#AmazonLinux 
#RedHat 
#CentOS 
#Windows"
#
#$OSVersion = Read-Host "Please input your OS Version for the kernal migration"
#if ($OSHashTable -notcontains $OSVersion) {
#    $OSVersion = Read-Host "Please input your OS Version for the kernal migration"
#}

#$Parameter = "@{'commands'=@('Command1', 'Command2')}"
#$Command = Send-SSMCommand -DocumentName AWS-RunShellScript -InstanceId $HVMInstanceId -Parameter $Parameter

#Check SSM Command Status
#Do  {
#$CommandState = (Get-SSMCommand -CommandId $Command).CommandId
#}
#Until ($CommandState -eq "Success")



#Prompt User to continue once kernel has been copied successfully
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Please ensure tasks to copy HVM Kernel to your PV EBS Volume have completed"
Do {
    $UserInput = Read-Host -Prompt "Please type continue once kernal migration is completed"
    if ($UserInput -eq "Continue")
        {"[$(get-date -Format "dd/mm/yy hh:mm:ss")] Continuing Script"}
    else
        {Read-Host "Type Continue once completed"}
   }
Until ($UserInput -eq "Continue")

#Stop HVM Instance and report back once in a stopped state
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping EC2 Instance" $HVMInstance.InstanceId 
Stop-EC2Instance -Region $Region -InstanceId $HVMInstance.InstanceId

Do  {
($InstanceState = (Get-EC2Instance -Region $Region -InstanceId $HVMInstance.InstanceId).Instances.State.Name.Value)
(SLEEP 5)    
}
Until ($InstanceState -eq "stopped")
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EC2 Instance is now stopped"

#Detach All EBS Volumes from HVM Instance
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Detaching EBS Volumes from HVM Instance" $HVMInstance.InstanceId
$HVMVolume = (Get-EC2Volume -Region $Region | ? { $_.Attachments.InstanceId -eq $HVMInstance.InstanceId})
foreach ($Volume in $HVMVolume) {
    Dismount-EC2Volume -Region $Region -InstanceId $HVMInstance.InstanceId -VolumeId $Volume.VolumeId
    Do {
    ($VolumeState = (Get-EC2Volume -Region $Region -VolumeId $Volume.VolumeId).State)
    (SLEEP 2)
    }
    Until ($VolumeState -eq "available")
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EBS Volumes detached successfully"

#Re-attach New Root Volume as root device to HVM Instance
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Attaching EBS Volume to HVM Instance as Root Device"
Add-EC2Volume -Region $Region -InstanceId $HVMInstance.InstanceId -VolumeId $MigrationVolume.VolumeId -Device /dev/xvda
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EBS Volume attached as root device successfully"

#Start HVM Instance
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Starting New HVM Instance" $HVMInstance.InstanceId
Start-EC2Instance -Region $Region -InstanceId $HVMInstance.InstanceId
Do {
    $HVMInstanceState = (Get-EC2Instance -InstanceId $HVMInstance.InstanceId -Region $Region).Instances.State.Name.Value
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting for instance to enter the running state"
    SLEEP 5
}
Until ($HVMInstanceState -eq "running")
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] HVM Instance" $HVMInstance.InstanceId "started successfully"


#Stop PV Instance
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Stopping EC2 Instance" $PVInstance.InstanceId 
Stop-EC2Instance -Region $Region -InstanceId $PVInstance.InstanceId

Do  {
($InstanceState = (Get-EC2Instance -Region $Region -InstanceId $PVInstance.InstanceId).Instances.State.Name.Value)
(SLEEP 5)    
}
Until ($InstanceState -eq "stopped")
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EC2 Instance is now stopped"

# Move Data Volumes from PV to HVM Instance
Write-Host ""
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving Data Volumes from PV Instance to new HVM Instance"

foreach ($Volume in $PVVolumes[1..($PVVolumes.length)]) {
    #Dismount Volume from PV Instance
    Dismount-EC2Volume -Region $Region -InstanceId $PVInstance.InstanceId -VolumeId $Volume.VolumeId

    #Wait until volume is dismounted
    Do {
        ($VolumeState = (Get-EC2Volume -Region $Region -VolumeId $Volume.VolumeId).State)
        (SLEEP 2)
    }
    Until ($VolumeState -eq "available")

    #Add Volume HVM Instance
    Add-EC2Volume -Region $Region -InstanceId $HVMInstance.InstanceId -VolumeId $Volume.VolumeId -Device $Volume.attachments.device
}

Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Data Volumes migrated from PV Instance to new HVM Instance successfully"