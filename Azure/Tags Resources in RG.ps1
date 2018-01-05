$RG = Get-AzureRmResource | Where-Object {$_.ResourceGroupName -eq "<RG_Name>"}

foreach($Resource in $RG) {Set-AzureRmResource -Tag @{ Application="<App_Name>"} -ResourceId $Resource.ResourceId}