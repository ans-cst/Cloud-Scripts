foreach ($vm in (Get-EC2Instance -Region eu-west-1 -Filter @{Name="availability-zone";Value="eu-west-1*"}).Instances)
{
 $tag = $vm.tags | ? { $_.key -eq "Name"} | Select -ExpandProperty Value;
 Write-host ($tag+"|"+$vm.Instanceid+"|"+$vm.Placement.AvailabilityZone) | Format-Table | Out-File -FilePath C:\Users\rfroggatt\desktop\AZBalance.csv -Encoding ASCII -Width 512};