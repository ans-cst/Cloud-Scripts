#Script to create SQS Queue

#Specify Access Key
$accesskey = read-host "Please Enter your Access Key:"

#Specify Secret Access Key
$secretaccesskey = read-host "Please Enter your Secret Access Key:"

#Login to AWS Account
Write-Host "Logging in to AWS Account"
Set-AWSCredentials -AccessKey $accesskey -SecretKey $secretaccesskey

#Specify Queue Name
$queuename = read-host "Please Enter your SQS Queue Name:"

#Specify Region
$region = read-host "Please Specify the Region to Create the Queue (us-east-1):"

#Specify Queue Wait Time
$waittime = read-host "Please Specify the SQS Queue Wait Time"

#Create SQS Queue
$QueueURL = New-SQSQueue -Region $region -QueueName $queuename -Attribute @{MessageRetentionPeriod = "259200"; MaximumMessageSize = "262144"; ReceiveMessageWaitTimeSeconds = $waittime.ToString(); VisibilityTimeout = "30"}
Write-Host "SQS Queue" $queuename "created successfully!"

#Print URL
Write-Host "Your SQS Queue URL is: "$QueueURL