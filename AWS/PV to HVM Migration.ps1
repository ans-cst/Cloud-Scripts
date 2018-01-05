#Script for Migrating to HVM Based AMI

#Set Environment Variables
$Region = ""
$AZ = ""
$Account = ""
$AccessKey = ""
$SecretKey = ""
$Parameter = "@{'commands'=@('Command1', 'Command2')}"
$PVInstanceID = ""
$HVMami = ""
$InstanceType = ""
$TempDeviceID = ""
$RootDeviceID = ""

#Logging in to Account
Write-Host "Logging in to " $Account " Account"
Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey ;

#Get Attached EBS Volume IDs
$PVVolume = (Get-EC2Volume -Region $Region | ? { $_.Attachments.InstanceId -eq $PVInstanceId}).VolumeId
$VolumeType = (Get-EC2Volume -Region $Region| ? { $_.Attachments.InstanceId -eq $PVInstanceId}).VolumeType

#Create Snapshot of EBS Volume
Write-Host "Creating EBS Volume Snapshot of PV Volume"
$SnapshotId = New-EC2Snapshot -Region $Region -VolumeId $VolumeID -Description "Migrating to HVM Based AMI"
Write-Host "EBS Snapshot Created Successfully"

#Confirm the Instance ID of your new HVM Instance
Write-Host "Creating new HVM Based EC2 Instance"
$HVMInstanceId = (New-EC2Instance -ImageId $HVMAMI -AvailabilityZone $AZ -Region $Region -InstanceType $InstanceType -MaxCount 1).Instances
$HVMInstanceId = $HVMInstanceId.InstanceId

#Create EBS Volume from Snapshot
Write-Host "Creating EBS Volume from PV Snapshot"
$PVVolumeId = New-EC2Volume -Region $Region -AvailabilityZone $AZ -SnapshotId $SnapshotId.SnapshotId -VolumeType $VolumeType
Write-Host "EBS Volume Created Successfully"

#Check New EBS Volume is Available
$PVVolumeId = Get-EC2Volume -Region $Region -VolumeId $PVVolumeId.VolumeId
Do {($VolumeState = (Get-EC2Volume -Region $Region -VolumeId $PVVolumeId.VolumeId).State)}
Until ($VolumeState -eq "available")

#Attach New EBS volume to new Instance ID
Write-Host "Attaching EBS Volume to HVM Instance"
Add-EC2Volume -Region $Region -InstanceId $HVMInstanceId -VolumeId $PVVolumeId.VolumeId -Device $TempDeviceID
Write-Host "EBS Volume Attached to HVM Instance successfully"

#Run Command to Migrate HVM Kernel to EBS Volume
$Command = Send-SSMCommand -DocumentName AWS-RunShellScript -InstanceId $HVMInstanceId -Parameter $Parameter

#Check SSM Command Status
Do  {($CommandState = (Get-SSMCommand -CommandId $Command.CommandId)}
Until ($CommandState -eq "Success")
Get-SSMCommand -CommandId $Command.CommandId

#Prompt User to continue once kernel has been copied
Write-Host "Please ensure tasks to copy HVM Kernel to your PV EBS Volume have completed"
Do {
    $UserInput = Read-Host -Prompt "Type Continue Once Completed"
    if ($UserInput -eq "Continue")
        {"Continuing Script"}
    else
        {Read-Host "Type Continue once completed"}
   }
Until ($UserInput -eq "Continue")

#Stop Instance and report back once in a stopped state
Stop-EC2Instance -Region $Region -InstanceId $HVMInstanceId
Write-Host "Allowing EC2 Instance to stop"
Do  {($InstanceState = (Get-EC2Instance -Region $Region -InstanceId $HVMInstanceId).Instances.State.Name.Value)}
Until ($InstanceState -eq "stopped")
Write-Host "EC2 Instance is now stopped"

#Detach EBS Volumes from HVM Instance
Write-Host "Detaching EBS Volumes from HVM Instance"
$HVMVolumeID = (Get-EC2Volume -Region $Region | ? { $_.Attachments.InstanceId -eq $HVMInstanceId}).VolumeId
Dismount-EC2Volume -Region $Region -InstanceId $HVMInstanceId -VolumeId $HVMVolumeID[0]
Dismount-EC2Volume -Region $Region -InstanceId $HVMInstanceId -VolumeId $HVMVolumeID[1]
Write-Host "EBS Volumes detached successfully"

#Checking EBS Volumes are available
Write-Host "Waiting for EBS Volumes to detach"
Do {($VolumeState = (Get-EC2Volume -Region $Region -VolumeId $HVMVolumeID[0]).State)}
Until ($VolumeState -eq "available")
Do {($VolumeState = (Get-EC2Volume -Region $Region -VolumeId $HVMVolumeID[1]).State)}
Until ($VolumeState -eq "available")

#Re-attach PV EBS Volume as root device
Write-Host "Attaching EBS Volume to HVM Instance as Root Device"
Add-EC2Volume -Region $Region -InstanceId $HVMInstanceId -VolumeId $PVVolumeId.VolumeId -Device $RootDeviceID
Write-Host "EBS Volume attached as root device successfully"

#Start HVM Instance
Write-Host "Starting New HVM Instance"
Start-EC2Instance -Region $Region -InstanceId $HVMInstanceId
Write-Host "HVM Instance started successfully"